class PaimentsController < ApplicationController
  def xshop
    @fees = Fee.for_sale
    @completed_karts = completed_karts
  end

  def xcart
    redirect_to xshop_path unless check_kart(:create)
  end

  def xcard
    redirect_to xshop_path unless check_kart { !@kart.items.empty? }
  end

  def xcharge
    if check_kart { !@kart.items.empty? && request.xhr? }
      @kart.purchase(params, current_user)
      if @kart.paid?
        complete_kart(@kart.id)
        begin
          IcuMailer.payment_receipt(@kart.id).deliver
        rescue => e
          logger.error "payment receipt for cart #{@kart.id} failed: #{e.message}"
        end
      end
    else
      if request.xhr?
        render nothing: true
      else
        redirect_to xshop_path
      end
    end
  end

  def xconfirm
    @kart = last_completed_kart
    redirect_to xshop_path unless @kart
  end

  def xcompleted
    @completed_karts = completed_karts
  end

  private

  def check_kart(option=nil)
    @kart = current_kart(option)
    @kart && (!block_given? || yield)
  end
end
