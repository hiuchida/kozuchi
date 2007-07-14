require File.dirname(__FILE__) + '/../../test_helper'
require 'settings/incomes_controller'

# Re-raise errors caught by the controller.
class Settings::IncomesController; def rescue_action(e) raise e end; end

class Settings::IncomesControllerTest < Test::Unit::TestCase
  fixtures :users, "account/accounts"
  set_fixture_class  "account/accounts".to_sym => 'account/base'

  def setup
    @controller = Settings::IncomesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # index のテスト
  def test_index
    get :index, {}, {:user_id => 1}
    assert_response :success
  end

  # create を get で呼ぶと失敗する
  def test_create_by_get
    get :create, {}, {:user_id => 1}
    assert_template '/open/not_found'
  end

  # create を  post で呼ぶと成功する。収入「臨時収入」を登録する。
  def test_create_visa
    post :create, {:account => {:name => '臨時収入', :sort_key => '10'}}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    assert_not_nil User.find(1).accounts.detect{|a| a.name == '臨時収入' && a.kind_of?(Account::Income)}
    assert_nil flash[:errors]
    assert_equal "収入内訳 '臨時収入' を登録しました。", flash[:notice]
  end

  # createのテスト。同じ名前がすでにあると失敗する。
  def test_create_cache
    count_before = @test_user_1.accounts(true).size
    post :create, {:account => {:name => 'ボーナス', :sort_key => '10'}}, {:user_id => 1}
    assert_redirected_to :action => 'index'
    assert_equal count_before, @test_user_1.accounts(true).size
    assert_not_nil flash[:errors]
  end
end
