# encoding: utf-8
require 'spec_helper'
require 'subdomain_capybara_server'

describe "Shop::Shops", js:true do

  let(:theme) { Factory :theme_woodland_dark }

  #let(:user_admin) {  with_resque { Factory :user_admin } }
  let(:user_admin) {  Factory :user_admin }

  let(:shop) do
    model = user_admin.shop
    model.update_attributes password_enabled: false
    model.themes.install theme
    model
  end

  let(:frontpage_collection) { shop.custom_collections.where(handle: 'frontpage').first }

  let(:iphone4) { Factory :iphone4, shop: shop, collections: [frontpage_collection] }

  let(:payment) { Factory :payment, shop: shop }

  before(:each) { Capybara::Server.manual_host = shop.primary_domain.host }

  after(:each) { Capybara::Server.manual_host = nil }

  describe "GET /products" do # 首页

    it "should show product" do
      payment
      product = iphone4
      variant = product.variants.first
      visit '/'
      click_on product.title
      page.should have_content(product.body_html)
      click_on '加入购物车'
      # 更新数量
      fill_in "updates_#{variant.id}", with: '2'
      find('form').click # 输入项失焦点触发更新事件
      find("#updates_#{variant.id}")[:value].should eql '2'
      click_on '结算'
      #收货人
      fill_in 'order[email]', with: 'mahb45@gmail.com'
      fill_in 'order[shipping_address_attributes][name]', with: '马海波'
      select '广东省', form: 'order[shipping_address_attributes][province]'
      select '深圳市', form: 'order[shipping_address_attributes][city]'
      select '南山区', form: 'order[shipping_address_attributes][district]'
      fill_in 'order[shipping_address_attributes][address1]', with: '科技园'
      fill_in 'order[shipping_address_attributes][phone]', with: '13928458888'
      choose '邮局汇款' #选择支付方式
      choose '普通快递-¥10.0' #选择配送方式
      click_on '提交订单'
      page.should have_content("您的订单号为： #1001")
    end

  end

  # 首页
  describe "GET /" do

    it "should list products" do
      iphone4
      visit '/'
      page.should have_content(iphone4.title)
    end

    it "should redirect to passowrd" do  # 密码保护
      shop.update_attributes password_enabled: true, password_message: '正在维护中...'
      visit '/'
      page.should have_content(shop.password_message)
      fill_in 'password', with: shop.password
      click_on '提交'
      page.should have_content('关于我们')
    end

    it "should redirect to unavailable page" do  # 密码保护
      shop.deadline = Date.new(2001,01,01)
      shop.save
      visit '/'
      page.should have_content "过期"
    end

    describe 'customer' do # 顾客

      it "should show register link" do  # 注册
        visit '/'
        page.should have_content "注册"
      end

    end

  end

  # 关于我们
  describe "GET /pages" do

    it "should list products!" do
      visit '/'
      click_on '关于我们'
      page.should have_content('介绍您的公司')
    end

  end

  # 商品列表
  describe "GET /collections/all" do

    it "should list products!" do
      iphone4
      visit '/'
      click_on '商品列表'
      page.should have_content(iphone4.title)
    end
  end

end
