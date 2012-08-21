# -*- encoding : utf-8 -*-
class AdminController < ApplicationController  

  def index
    if current_user.nil?
      flash[:notice] = "You need to be signed in to access group policies"
      redirect_to new_user_session_path
    elsif cannot? :manage, Admin::Group 
      flash[:notice] = "You do not have sufficient privileges to access group policies"
      redirect_to root_path
    else    
      render layout: 'admin'
    end
  end
end 
