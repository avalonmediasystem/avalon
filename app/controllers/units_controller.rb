require "role_controls"
class UnitsController < ApplicationController
  before_filter :authenticate_user!, :set_parent_name!
  load_and_authorize_resource

  def create
    @unit = Unit.new(params[:unit])
    if @unit.save
      redirect_to polymorphic_path([@parent_name, @unit])
    else
      render 'new'
    end
  end

  def update
    @unit = Unit.find(params[:id])
    if @unit.update_attributes params[:unit]
      redirect_to polymorphic_path([@parent_name, @unit]), flash: { notificaton: restful_flash_message }
    else
      render 'edit'
    end
  end

  private

    def restful_flash_message
      action_past_tense = case params[:action]
        when 'create'
          'created'
        when 'update'
          'updated'
        when 'destroy'
          'deleted'
        end
      "Successfully #{action_past_tense} #{controller_name.downcase.singularize}." if action_past_tense
    end

    def set_parent_name!
      @parent_name =  params[:controller].to_s.split('/')[-2..-2].try :first
    end

end