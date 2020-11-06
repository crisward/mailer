require "base64"

module Mailer
  class Mock < Provider
    @apikey = ""
    @domain = ""

    # Setup mock library
    #
    # ```ruby
    # Mailer::Mock.setup()
    # ```
    def initialize
    end

    def send(message)
      to = message.to.map { |recip| recip.to_s }.join(",")
      cc = message.cc.map { |recip| recip.to_s }.join(",")
      bcc = message.bcc.map { |recip| recip.to_s }.join(",")
      text = message.text
      html = message.html
      attachments = message.attachments
      inline = message.inline
      io = IO::Memory.new
      m = MIME::Multipart::Builder.new(io)
      m.content_type("form-data")
      add m, "from", message.from
      add m, "to", to
      add m, "cc", cc if cc.size > 0
      add m, "bcc", bcc if bcc.size > 0
      add m, "subject", message.subject
      add m, "text", text if text.size > 0
      add m, "html", html if html.size > 0
      if attachments.size > 0
        attachments.each do |attachment|
          add_file m, attachment.path, attachment.filename
        end
      end
      if inline.size > 0
        inline.each do |attachment|
          add_file m, attachment.path, attachment.filename, "inline"
        end
      end
      m.finish
      message = io.to_s
      return message
    end

    private def add(multipart, name, val)
      multipart.body_part HTTP::Headers{"content-disposition" => %{form-data; name="#{name}"}}, val
    end

    private def add_file(multipart, filepath, filename, filetype = "attachment")
      multipart.body_part(HTTP::Headers{"content-disposition" => %{form-data; name="#{filetype}"; filename="#{filename}"}}) do |io|
        ::File.open(filepath, "r") do |file|
          IO.copy(file, io)
        end
      end
    end
  end
end
