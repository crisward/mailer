require "./mailer/*"
require "http"
# Sending Emails
#
# ## Full Example
#
# ```crystal
# Mailer.config(provider: Mailer::Mailgun.new(apikey, domain))
# email = Mailer::Message.new
# email.to("bill@microsoft.com", "Cris Ward")
# email.to("steve@apple.com")
# email.from("linus@linux.org")
# email.subject("Hello")
# email.text = "Some plain text messaeg"
# email.html = "<p>Some html message <img src='cid:hello.jpg'></p>"
# email.attachment = Mailer::Attachment.new(filename:"logo.jpg" , path: "./storage/public/images/logo.jpg")
# email.inline("./storage/public/images/hello.jpg")
# email.send
# ```
module Mailer
  @@provider : Mailer::Provider?
  
  abstract class Mailer::Provider
    abstract def send(email)
  end

  def self.config(@@provider : Mailer::Provider)
  end

  def self.provider 
    @@provider
  end

  class Recipient

    JSON.mapping({
      email:{type: String, nilable: true},
      name:{type: String, nilable: true}
    })

    def to_s
      if @email && @name
        return "#{@name} <#{@email}>"
      end 
      if @email 
        return "#{@email}"
      end
      return nil
    end

    def initialize(@email,@name="")
    end
  end

  class Attachment
    def initialize(@filename, @path)
    end

    property filename : String, path : String
  end

  class Message
    @from = ""
    setter subject, text, html, from = ""
    getter to, cc, bcc, from, subject, text, html, attachments, inline

    def initialize
      @to = [] of Recipient
      @cc = [] of Recipient
      @bcc = [] of Recipient
      @from = ""
      @subject = "no subject"
      @text = ""
      @html = ""
      @attachments = [] of Attachment
      @inline = [] of Attachment
    end

    # Add a recipient
    #
    # ```
    # email = Mailer::Mailgun::Message.new
    # email.to("user@email.com")
    # ```
    def to(email)
      @to << Recipient.new(email)
    end

    # Add recipient with name
    #
    # ```
    # email = Mailer::Mailgun::Message.new
    # email.to("user@email.com", "Cris Ward")
    # ```
    def to(email, name)
      @to << Recipient.new(email,name) #"#{name} <#{email}>"
    end

    # Add CC
    #
    # ```
    # email.cc("bob@here.com")`
    # ```
    def cc(email)
      @cc << Recipient.new(email)
    end

    # Add CC with name
    #
    # ```
    # email.cc("bob@here.com", "Bob")
    # ```
    def cc(email, name)
      @cc << Recipient.new(email,name)
    end

    # Add BCC
    #
    # ```
    # email.cc("bob@here.com")
    # ```
    def bcc(email)
      @bcc << Recipient.new(email)
    end

    # Add BCC with name
    #
    # ```
    # email.cc("bob@here.com", "Bob")
    # ```
    def bcc(email, name)
      @bcc << Recipient.new(email,name)
    end

    # Add Attachment
    # Can be called mutlple times to add multiple attachments
    #
    # ```
    # email.attachment = Mailer::Attachment.new(filename:"logo.jpg" , path: "./storage/public/images/logo.jpg")
    # ```
    def attachment=(attachment : Attachment)
      @attachments << attachment
    end

    # Add Inline attachment (usually image)
    # Can be called mutlple times to add multiple attachments
    #
    # ```html
    # <p>Some content <image src="cid:hello.jpg" />
    # ```
    # ```crystal
    # email.attachment = Mailer::Attachment.new(filename:"hello.jpg" , path: "./storage/public/images/hello.jpg")
    # ```
    def inline=(attachment : Attachment)
      @inline << attachment
    end

    # Sends the email
    #
    # ```
    # email.send
    # ```
    def send
      provider = Mailer.provider
      raise "You have not setup a mail provider" if !provider
      provider.send(self)
    end
  end
end