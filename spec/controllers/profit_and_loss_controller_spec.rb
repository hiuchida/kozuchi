# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe ProfitAndLossController, type: :controller do
  fixtures :users, :accounts

  before do
    login_as :taro
  end
  describe "show" do
    context "口座が十分あるとき" do
      it "monthlyにリダイレクトされる" do
        get :show
        expect(response).to redirect_to(monthly_profit_and_loss_path(:year => Date.today.year, :month => Date.today.month))
      end
    end
    context "口座がないとき" do
      before do
        Account::Base.where(user_id: @current_user.id).delete_all # destroy_all だと記入が邪魔で削除できない　関連スタートは dependent destroy 依存
      end
      it "エラーページが表示される" do
        get :show
        expect(response).to be_successful
      end
    end
  end
  describe "monthly" do
    it "成功する" do
      get :monthly, params: {:year => Date.today.year, :month => Date.today.month}
      expect(response).to be_successful
    end
  end
end