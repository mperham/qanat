require "tempfile"

module EventedMagick
  class ImageTempFile < Tempfile
    def make_tmpname(ext, n)
      'mini_magick%d-%d%s' % [$$, n, ext ? ".#{ext}" : '']
    end
  end
end
