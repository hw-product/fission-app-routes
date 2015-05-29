class Admin::PayloadMatchRulesController < ApplicationController

  def index
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to dashboard_path
      end
      format.html do
        @rules = PayloadMatchRule.order(:name).all
      end
    end
  end

  def new
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to dashboard_url
      end
      format.html
    end
  end

  def create
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to dashboard_url
      end
      format.html do
        begin
          PayloadMatchRule.new(
            :name => params[:name],
            :payload_key => params[:payload_key],
            :description => params[:description]
          ).save
          flash[:success] = 'New payload match rule created!'
        rescue => e
          Rails.logger.error "Failed to create PayloadMatchRule: #{e.class} - #{e}"
          Rails.logger.debug "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          flash[:error] = "Failed to create payload match rule! (#{e})"
        end
        redirect_to admin_payload_match_rules_path
      end
    end
  end

  def edit
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to dashboard_url
      end
      format.html do
        @rule = PayloadMatchRule.find_by_id(params[:id])
        unless(@rule)
          flash[:error] = 'Failed to locate requested payload match rule!'
          redirect_to admin_payload_match_rules_path
        end
      end
    end
  end

  def update
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to dashboard_url
      end
      format.html do
        rule = PayloadMatchRule.find_by_id(params[:id])
        if(rule)
          rule.payload_key = params[:payload_key]
          rule.description = params[:description]
          begin
            rule.save
            flash[:success] = 'Payload match rule updated!'
          rescue => e
            Rails.logger.error "Failed to update PayloadMatchRule (#{rule}): #{e.class} - #{e}"
            Rails.logger.debug "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
            flash[:error] = "Failed to update payload match rule! (#{e})"
          end
        else
          flash[:error] = 'Failed to locate requested payload match rule!'
        end
        redirect_to admin_payload_match_rules_path
      end
    end
  end

  def destroy
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to dashboard_url
      end
      format.html do
        rule = PayloadMatchRule.find_by_id(params[:id])
        if(rule)
          begin
            rule.destroy
            flash[:success] = 'Destroyed payload match rule!'
          rescue => e
            Rails.logger.error "Failed to destroy PayloadMatchRule (#{rule}): #{e.class} - #{e}"
            Rails.logger.debug "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
            flash[:error] = "Failed to destroy payload match rule! (#{e})"
          end
        else
          flash[:error] = 'Failed to locate requested payload match rule!'
        end
        redirect_to admin_payload_match_rules_path
      end
    end
  end

end
