class WebhooksController < ApplicationController
  include FilterScoped

  before_action :set_webhook, except: %i[ index new create ]

  def index
    set_page_and_extract_portion_from Webhook.all.ordered
  end

  def show
  end

  def new
    @webhook = Webhook.new
  end

  def create
    @webhook = Webhook.new(webhook_params)

    if @webhook.save
      redirect_to @webhook, status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @webhook.update(webhook_params.except(:url))
      redirect_to @webhook, status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @webhook.destroy!
    redirect_to webhooks_path, status: :see_other
  end

  private
    def set_webhook
      @webhook = Webhook.find(params[:id])
    end

    def webhook_params
      params.require(:webhook).permit(:name, :url, subscribed_actions: [])
    end
end
