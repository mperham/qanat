# == Schema Information
#
# Table name: page
#
#  id                         :integer       not null, primary key
#  compare_url                :text          not null
#  fetch_url                  :text          
#  scraped_at                 :datetime      
#  mime_type                  :string(255)   
#  created_at                 :datetime      not null
#  fetched_at                 :datetime      
#  is_links_created           :boolean       
#  default_entry_id           :integer       
#  default_entry_feed_id      :integer       
#  default_entry_published_at :datetime      
#  link_to_page_ids           :string        
#  embedded_image_id          :string        
#  selected_image_id          :binary        
#

class Publication < ActiveRecord::Base; end

class Page < ActiveRecord::Base

  # 514063606 514051951 514052089
  def embedded_image_ids(context = nil)
    embedded_image_ids = []
    
    if embedded_image_id
      value = embedded_image_id[2..-3].gsub(/\\\\/, '\\')
      embedded_image_ids += unescape_bytea(value).split('","').map { |s| s.unpack('H*')[0] }
    end
    
    embedded_image_ids
  end
  
  def unescape_bytea(value)
    if value =~ /\\\d{3}/
      result = ''
      i, max = 0, value.size
      while i < max
        char = value[i]
        if char == ?\\
          if value[i+1] == ?\\
            char = ?\\
            i += 1
          else
            char = value[i+1..i+3].oct
            i += 3
          end
        end
        result << char
        i += 1
      end
      result
    else
      value
    end
  end
  
  
  def escape_bytea(value)
    result = ''
    value.each_byte { |c| result << sprintf('\\\\%03o', c) }
    result
  end
  
  def embedded_image_id=(values)
    return write_attribute(:embedded_image_id, nil) unless values
    return write_attribute(:embedded_image_id, values) if values[0..0] == '{' and values[-1..-1] == '}' #tests
    
    strs = Array(values).map do |value|
      if value.size == 20 # raw binary string
        value
      elsif value.size == 40 # hex string
        [value].pack('H*')
      else
        raise ArgumentError, "Invalid value: #{value} in #{values.inspect}"
      end
    end

    # Binary data with Postgresql and Rails is pure misery.
    # Rather than dealing with which characters need to be escaped and which don't,
    # we just escape everything.  The native driver's PGconn.escape_bytea function just
    # escapes 'necessary' characters for plain bytea columns, which doesn't work
    # when writing to bytea[].
    escaped = strs.map { |str| escape_bytea(str) }.join('","')
    result = "{\"#{escaped}\"}"
    
    # Don't want Rails to do its own quoting of the value so we update directly.
    connection.update("update page set embedded_image_id = $hash$#{result}$hash$ where id = #{self.id}", 'update embedded')
  end
  
  def selected_image_id=(value)
    if value.nil? || value.size == 20 # raw binary string
      write_attribute(:selected_image_id, value)
    elsif value.size == 40 # hex string
      write_attribute(:selected_image_id, [value].pack('H*'))
    else
      raise ArgumentError, "Invalid value: #{value}"
    end
    @selected_image_id = nil
  end
  
  NO_IMAGE = "0" * 40
  
  def selected_image_id
    @selected_image_id ||= (image_id = read_attribute(:selected_image_id)) && image_id.unpack("H*")[0]
  end
  
end
