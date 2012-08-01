require 'spec_helper'

describe Comment do 
  before(:each) do
    @comment_test = Comment.new(name: "John Smith",
      email: "john.smith@example.com",
      email_confirmation: "john.smith@example.com",
      subject: Comment::SUBJECTS[2],
      comment: "This is an RSpec test") 
  end
  
  it "should validate if all fields are entered correctly" do
    @comment_test.should be_valid
  end
  
  it "should fail if the name is missing" do
    @comment_test.name = nil
    @comment_test.should_not be_valid
  end
  
  describe "Subject" do
    it "should fail if there is no subject" do
      @comment_test.subject = nil
      @comment_test.should_not be_valid
    end
    
    it "should fail if the subject is not in the list" do
      @comment_test.subject = 'Not in the list'
      @comment_test.should_not be_valid    
    end
  end
  
  describe "Comments" do
    it "should fail if there is no comment" do
      @comment_test.comment = nil
      @comment_test.should_not be_valid
    end
    
    it "should strip out any unsafe HTML" do
      @comment_test.comment = 
        "<script>alert('This would be an exploit')</script><p>But this is safe</p>"
      @comment_test.comment.should_not match /\<script\>.*\<\\script\>/
    end
  end
  
  describe "Email validation" do
    it "should warn if the addresses do not match" do
      @comment_test.email = "email_one@example.com"
      @comment_test.email_confirmation = "email_two@example.com"
      @comment_test.should_not be_valid
    end
    
    it "should warn if an address is invalid" do
      @comment_test.email = "nosuchemail@"
      @comment_test.should_not be_valid
    end
    
    it "should have matching email addresses" do
      @comment_test.should be_valid
    end
  end
  
  describe "Captcha" do
    it "should fail if a captcha value is entered" do
      @comment_test.nickname = 'Not empty'
      @comment_test.should_not be_valid
    end
  end
end