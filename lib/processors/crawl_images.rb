require 'evented_magick'
require 'tempfile'
require 'page'

class CrawlImages
  
  def initialize
    @tempfiles = []
  end
  
  def process(hash, priority)
    rerender = false
    with_cleanup do
      page_ids = hash[:pages]
      page_ids.each do |page_id|
        logger.debug "Processing page #{page_id}"
        processed = process_images_for Page.find(page_id), hash[:force]
        rerender ||= processed
      end
    end
    
    # trigger re-render of publication when processing is done
    if false and hash[:publication_id] and pub = Publication.find_by_id(hash[:publication_id])
      tasks.push(YAML::dump(
        { :type => 'publication', :id => pub.id, :deep => true, 
          :msg_type => 'render_item', :msg_created_at => Time.now.to_i }
      ))
    end
  end
  
  private
  
  def tasks
    @tasks ||= SQS::Queue.new('tasks_production_highest')
  end
  
  def logger
    DaemonKit.logger
  end
  
  def with_cleanup
    begin
      yield
    ensure
      @tempfiles.each do |tempfile|
        tempfile.unlink
      end
    end
  end
  
  def process_images_for(page, force = false)
    # page already has an image selected for it.
    # this means we've already processed the images
    # for this page.
    return false if page.selected_image_id and !force

    valid = nil
    best_image_id = Page::NO_IMAGE
    best_size = 0
    
    page.embedded_image_ids.each do |image_id|
      logger.debug "Processing image #{image_id}"
      attribs = simpledb.get(image_id)

      process_image(page, image_id, attribs)

      if valid?(attribs)
        size = Integer(attribs['width']) * Integer(attribs['height'])
        if size > best_size
          best_image_id = image_id
          best_size = size
        end

        (valid ||= []) << image_id
      else
        logger.debug "Invalid image: #{attribs.inspect}"
      end
    end
    
    logger.debug "Valid images: #{valid.inspect}"
    page.selected_image_id = best_image_id
    page.embedded_image_id = valid
    page.save!
    true
  end
  
  def process_image(page, image_id, attribs)
    start_state = state_for(attribs)
    # Don't re-process images already in these states
    return if %w(invalid valid).include? start_state
    
    begin
      image_path = fetch_image(page, attribs)
      return unless image_path
      return unless valid_image?(image_path, attribs)
  
      upload_to_s3(image_path, "#{image_id}.#{attribs['type']}")
      valid_id = image_id

      attribs['state'] = 'valid'
      true
    ensure
      if start_state != state_for(attribs)
        simpledb.put(image_id, attribs)
      end
    end
  end
  
  def state_for(attribs)
    if attribs['state']
      attribs['state'].is_a?(String) ?
        attribs['state'] :
        attribs['state'][0]
    else
      nil
    end
  end
  
  def valid?(attribs)
    state_for(attribs) == 'valid'
  end
  
  def upload_to_s3(image_path, id)
    s3.put_file(id, File.read(image_path))
  end
  
  def valid_image?(path, attribs)
    begin
      image = EventedMagick::Image.new(path)
      (width, height) = image['dimensions']
      type = image['format'].downcase
    
      attribs['type'] = type
      attribs['width'] = width
      attribs['height'] = height

      # ignore image if too small
      if width < 50 || height < 50
        attribs['state'] = 'invalid'
        return false
      end
    
      # ar = width / Float(height)
      # # ignore image if too wild in aspect ratio
      # if ar < 0.5 || ar > 1.7
      #   puts "Not square-ish, invalid"
      #   attribs['state'] = 'invalid'
      #   return false
      # end
    
      true
    rescue Exception => ex
      logger.info("Invalid image: #{ex.class.name}: #{ex.message}")
      attribs['state'] = 'invalid'
      false
    end
  end
  
  def fetch_image(page, attribs)
    begin
      fetch_url = attribs['fetch_url']
      url = URI.parse(fetch_url)
      # ticket 3140
      if !(url.is_a?(URI::HTTP) or url.is_a?(URI::HTTPS))
        attribs['state'] = 'invalid'
        return nil
      end

      headers = {
        'Referer' => page.fetch_url,
      }
      a = Time.now
      http = async_operation(:get, url, { :head => headers })
      code = http.response_header.status
      logger.info("fetching image #{url} took #{Time.now - a} sec: #{code}")
  
      # Treat 300 and 400 status codes as unrecoverable
      if (300..499).include?(code)
        attribs['state'] = 'invalid'
        return nil
      end

      # Treat 500 status codes as recoverable (we'll try again at some time in
      # the future if this image is ever referenced again).
      if code >= 500
        attribs['state'] = 'error'
        return nil
      end
    
      temp = Tempfile.new('original')
      temp.write(http.response)
      temp.close
      @tempfiles << temp
  
      temp.path
    # Debugging for #3137
    rescue NoMethodError => nme
      logger.warn("Fail: NME '#{fetch_url}' #{url.inspect} #{nme.message} #{page.id}")
      attribs['state'] = 'error'
      return nil      
    rescue URI::InvalidURIError => baduri
      logger.warn("Fail: Invalid URI: #{fetch_url} on page #{page.id}")
      attribs['state'] = 'invalid'
      return nil
    rescue SocketError => se # getaddrinfo: Name or service not known
      logger.warn("Fail: SocketError from #{fetch_url}: #{se.message}")
      attribs['state'] = 'error'
      return nil
    rescue SystemCallError => sc # Errno::ECONNREFUSED and friends
      logger.warn("Fail: SystemCallError from #{fetch_url}: #{sc.message}")
      attribs['state'] = 'error'
      return nil
    rescue IOError => ie # EOFError and other streaming issues
      logger.warn("Fail: I/O Error from #{fetch_url}: #{ie.message}")
      attribs['state'] = 'error'
      return nil
    end
  end
  
  def async_operation(method, uri, opts)
    f = Fiber.current
    http = EventMachine::HttpRequest.new(uri).send(method, opts)
    http.callback { f.resume(http) }
    http.errback { f.resume(http) }

    return Fiber.yield
  end
  

  def s3
    @s3 ||= begin
      S3::Bucket.new("images.production.onespot.com")
    end
  end
  
  def simpledb
    @db ||= begin
      SDB::Database.new("images-production")
    end
  end
end