require "role_controls"
class UnitsController < ApplicationController
  before_filter :authenticate_user!, :set_parent_name!
  load_and_authorize_resource
  respond_to :html
  responders :flash

  def index
    @units = search_sort_paginate(params, Unit.scoped)
  end

  def create
    @unit = Unit.new(params[:unit])
    @unit.created_by_user_id = current_user.user_key
    if @unit.save
      respond_with @unit do |format|
        format.html { redirect_to [@parent_name, @unit] }
      end
    else
      render 'new'
    end
  end

  def update
    @unit = Unit.find(params[:id])
    if @unit.update_attributes params[:unit]
      respond_with @unit do |format|
        format.html { redirect_to [@parent_name, @unit] }
      end
    else
      render 'edit'
    end
  end

  def destroy
    @unit.destroy
    respond_with @unit do |format|
      format.html { redirect_to [@parent_name, @unit] }
    end
  end

  private

    def set_parent_name!
      @parent_name =  params[:controller].to_s.split('/')[-2..-2].try :first
    end

end