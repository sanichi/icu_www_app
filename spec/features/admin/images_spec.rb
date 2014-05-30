require 'spec_helper'

describe Image do
  let(:caption)      { I18n.t("image.caption") }
  let(:credit)       { I18n.t("image.credit") }
  let(:edit)         { I18n.t("edit") }
  let(:delete)       { I18n.t("delete") }
  let(:file)         { I18n.t("file") }
  let(:save)         { I18n.t("save") }
  let(:unauthorized) { I18n.t("errors.alerts.unauthorized") }
  let(:year)         { I18n.t("year") }

  let(:failure)      { "div.alert-danger" }
  let(:field_error)  { "div.help-block" }
  let(:success)      { "div.alert-success" }
  let(:success_text) { "successfully created" }

  let(:image_dir)    { Rails.root + "spec/files/images/" }
  let(:event_dir)    { Rails.root + "spec/files/events/" }

  def expect_data(image, file, size, type, width, height)
    expect(image.data_file_name).to eq file
    expect(image.data_file_size).to eq size
    expect(image.data_content_type).to eq type
    expect(image.dimensions).to be_a Hash
    expect(image.dimensions[:original]).to be_a Array
    expect(image.dimensions[:original][0]).to eq width
    expect(image.dimensions[:original][1]).to eq height
    expect(image.dimensions[:thumbnail]).to be_a Array
  end

  def expect_data_april(image)
    expect_data(image, "april.jpeg", 21710, "image/jpeg", 300, 219)
    expect(image.dimensions[:thumbnail][0]).to eq 100
    expect(image.dimensions[:thumbnail][1]).to be < 100
  end

  def expect_data_suzanne(image)
    expect_data(image, "suzanne.gif", 105733, "image/gif", 417, 480)
    expect(image.dimensions[:thumbnail][0]).to be < 100
    expect(image.dimensions[:thumbnail][1]).to eq 100
  end

  def expect_data_gearoidin(image)
    expect_data(image, "gearoidin.png", 118210, "image/png", 256, 256)
    expect(image.dimensions[:thumbnail][0]).to eq 100
    expect(image.dimensions[:thumbnail][1]).to eq 100
  end

  context "authorization" do
    let(:level1) { ["admin", user] }
    let(:level2) { ["editor"] }
    let(:level3) { User::ROLES.reject { |r| r == "admin" || r == "editor" }.append("guest") }
    let(:user)   { create(:user, roles: "editor") }
    let!(:image) { create(:image, user: user) }

    def cell(label)
      "//th[.='#{label}']/following-sibling::td"
    end

    def href(image)
      "a[href='/images/#{image.id}']"
    end

    it "admin and owner can update as well as create" do
      level1.each do |role|
        login role
        visit new_admin_image_path
        expect(page).to_not have_css(failure)
        visit edit_admin_image_path(image)
        expect(page).to_not have_css(failure)
        visit images_path
        find(href(image)).click
        expect(page).to have_xpath(cell(caption), text: image.caption)
        expect(page).to have_link(edit)
      end
    end

    it "other editors can only create" do
      level2.each do |role|
        login role
        visit new_admin_image_path
        expect(page).to_not have_css(failure)
        visit edit_admin_image_path(image)
        expect(page).to have_css(failure)
        visit images_path
        find(href(image)).click
        expect(page).to have_xpath(cell(caption), text: image.caption)
        expect(page).to_not have_link(edit)
      end
    end

    it "other roles and guests can only view" do
      level3.each do |role|
        login role
        visit new_admin_image_path
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_image_path(image)
        expect(page).to have_css(failure, text: unauthorized)
        visit images_path
        find(href(image)).click
        expect(page).to have_xpath(cell(caption), text: image.caption)
        expect(page).to_not have_link(edit)
      end
    end
  end

  context "create" do
    before(:each) do
      @user = login("editor")
      visit new_admin_image_path
    end

    it "JPG" do
      fill_in caption, with: "April"
      fill_in year, with: "1986"
      fill_in credit, with: "Mark Orr"
      attach_file file, image_dir + "april.jpeg"
      click_button save

      expect(page).to have_css(success, text: success_text)
      expect(Image.count).to eq 1
      image = Image.first

      expect(image.caption).to eq "April"
      expect(image.year).to eq 1986
      expect(image.credit).to eq "Mark Orr"
      expect(image.user_id).to eq @user.id
      expect_data_april(image)
    end

    it "GIF" do
      fill_in caption, with: "Suzanne"
      fill_in year, with: "2004"
      attach_file file, image_dir + "suzanne.gif"
      click_button save

      expect(page).to have_css(success, text: success_text)
      expect(Image.count).to eq 1
      image = Image.first

      expect(image.caption).to eq "Suzanne"
      expect(image.year).to eq 2004
      expect(image.user_id).to eq @user.id
      expect_data_suzanne(image)
    end

    it "PNG" do
      fill_in caption, with: "Gearóidín"
      fill_in year, with: "2006"
      fill_in credit, with: "Mark Orr"
      attach_file file, image_dir + "gearoidin.png"
      click_button save

      expect(page).to have_css(success, text: success_text)
      expect(Image.count).to eq 1
      image = Image.first

      expect(image.caption).to eq "Gearóidín"
      expect(image.year).to eq 2006
      expect(image.credit).to eq "Mark Orr"
      expect(image.user_id).to eq @user.id
      expect_data_gearoidin(image)
    end

    it "invalid type" do
      fill_in caption, with: "Test"
      fill_in year, with: "2006"
      fill_in credit, with: "Mark Orr"
      attach_file file, event_dir + "ennis_2014.pdf"
      click_button save

      expect(page).to_not have_css(success)
      expect(page).to have_css(field_error, text: "invalid")
      expect(Image.count).to eq 0
    end
  end

  context "edit" do
    let(:user)      { create(:user, roles: "editor" ) }
    let(:april)     { attributes_for(:image_april) }
    let(:suzanne)   { attributes_for(:image_suzanne) }
    let(:gearoidin) { attributes_for(:image_gearoidin) }
    let!(:image)    { create(:image_april, user: user) }

    before(:each) do
      login user
      visit image_path(image)
    end

    it "image data only" do
      click_link edit
      attach_file file, image_dir + "gearoidin.png"
      click_button save

      image.reload

      expect(image.caption).to eq april[:caption]
      expect(image.year).to eq april[:year]
      expect(image.credit).to eq april[:credit]

      expect_data_gearoidin(image)
    end

    it "meta data only" do
      click_link edit
      fill_in caption, with: suzanne[:caption]
      fill_in year, with: suzanne[:year].to_s
      fill_in credit, with: suzanne[:credit].to_s
      click_button save

      image.reload

      expect(image.caption).to eq suzanne[:caption]
      expect(image.year).to eq suzanne[:year]
      expect(image.credit).to eq suzanne[:credit]

      expect_data_april(image)
    end

    it "both" do
      click_link edit
      fill_in caption, with: gearoidin[:caption]
      fill_in year, with: gearoidin[:year].to_s
      fill_in credit, with: gearoidin[:credit].to_s
      attach_file file, image_dir + "gearoidin.png"
      click_button save

      image.reload

      expect(image.caption).to eq gearoidin[:caption]
      expect(image.year).to eq gearoidin[:year]
      expect(image.credit).to eq gearoidin[:credit]

      expect_data_gearoidin(image)
    end
  end

  context "delete" do
    let(:user)   { create(:user, roles: "editor") }
    let!(:image) { create(:image, user: user) }

    it "by owner" do
      login user
      visit image_path(image)
      click_link delete
      expect(Image.count).to be 0
    end

    it "by non-owner" do
      login "editor"
      visit image_path(image)
      expect(page).to_not have_link(delete)
    end
  end
end
