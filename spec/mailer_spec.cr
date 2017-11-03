require "./spec_helper"

describe Mailer do

  it "test mock driver" do
    Mailer.config(provider: Mailer::Mock.new())
    email = Mailer::Message.new
    email.to("bill@microsoft.com", "Cris Ward")
    email.to("steve@apple.com")
    email.from = "linus@linux.org"
    email.subject = "Hello"
    email.text = "Some plain text messaeg"
    email.html = "<p>Some html message <img src='cid:logo.jpg'></p>"
    email.attachment = Mailer::Attachment.new(filename: "test.pdf" , path: "./spec/test.pdf")
    email.inline = Mailer::Attachment.new(filename: "logo.jpg" , path: "./spec/test.png")
    encoded = email.send
    if encoded && encoded.is_a?(String)
      encoded.size.should eq(43024)
    end
  end

  if ENV["MAILGUN_KEY"]? && ENV["MAILGUN_DOMAIN"]? && ENV["EMAIL"]? 
    it "it should send a real email and return a email id" do
      Mailer.config(provider: Mailer::Mailgun.new(key: ENV["MAILGUN_KEY"], domain: ENV["MAILGUN_DOMAIN"]))
      email = Mailer::Message.new
      email.to(ENV["EMAIL"])
      email.from = ENV["EMAIL"]
      email.subject = "Hello"
      email.text = "Some plain text messaeg"
      email.html = "<p>Some html message <img src='cid:logo.jpg'></p>"
      email.attachment = Mailer::Attachment.new(filename: "test.pdf" , path: "./spec/test.pdf")
      email.inline = Mailer::Attachment.new(filename: "logo.jpg" , path: "./spec/test.png")
      id = email.send
      id.should contain(ENV["MAILGUN_DOMAIN"])
    end
    
    it "should raise when api key is wrong using send" do 
      Mailer.config(provider: Mailer::Mailgun.new(key: "blahblah", domain: ENV["MAILGUN_DOMAIN"]))
      email = Mailer::Message.new
      email.to(ENV["EMAIL"])
      email.from = ENV["EMAIL"]
      email.subject = "Hello"
      email.text = "Some plain text messaeg"
      expect_raises(Exception) do 
        email.send
      end
    end

    it "should return nil when api key is wrong using send?" do 
      Mailer.config(provider: Mailer::Mailgun.new(key: "blahblah", domain: ENV["MAILGUN_DOMAIN"]))
      email = Mailer::Message.new
      email.to(ENV["EMAIL"])
      email.from = ENV["EMAIL"]
      email.subject = "Hello"
      email.text = "Some plain text messaeg"
      email.send?.should be_nil
    end
  end

  if ENV["SENDGRID_KEY"]? && ENV["EMAIL"]? 
    it "test mock driver" do
      Mailer.config(provider: Mailer::Sendgrid.new(key: ENV["SENDGRID_KEY"]))
      email = Mailer::Message.new
      email.to(ENV["EMAIL"])
      email.from = ENV["EMAIL"]
      email.subject = "Hello"
      email.text = "Some plain text message"
      email.html = "<p>Some html message <img src='cid:logo.jpg'></p>"
      email.attachment = Mailer::Attachment.new(filename: "test.pdf" , path: "./spec/test.pdf")
      email.inline = Mailer::Attachment.new(filename: "logo.jpg" , path: "./spec/test.png")
      p email.send
      p "check your email - it should have been sent via sendgrid"
    end
  end

end