require 'spec_helper'

describe Image do
  let(:button)          { I18n.t("edit") }
  let(:caption)         { I18n.t("image.caption") }
  let(:credit)          { I18n.t("image.credit") }
  let(:edit)            { I18n.t("edit") }
  let(:file)            { I18n.t("image.file") }
  let(:save)            { I18n.t("save") }
  let(:signed_in_as)    { I18n.t("session.signed_in_as") }
  let(:unauthorized)    { I18n.t("errors.alerts.unauthorized") }
  let(:year)            { I18n.t("image.year") }

  let(:failure)         { "div.alert-danger" }
  let(:success)         { "div.alert-success" }
  let(:success_text)    { "successfully created" }

  let(:image_dir)       { Rails.root + "spec/files/images/" }

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
    let(:ok_roles)        { %w[admin editor] }
    let(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) } }

    let(:caption_text)    { "Fractal" }
    let(:year_text)       { "2014" }
    let(:credit_text)     { "Mark Orr" }
    let(:image_file)      { "fractal.jpg" }
    let(:image_path)      { image_dir + image_file }

    before(:each) do
      login "admin"
      visit new_admin_image_path
      fill_in caption, with: caption_text
      fill_in year, with: year_text
      fill_in credit, with: credit_text
      attach_file file, image_path
      click_button save
      logout

      expect(Image.count).to be 1
      @image = Image.first
    end

    def cell(label)
      "//th[.='#{label}']/following-sibling::td"
    end

    it "some roles can manage images as well as view" do
      ok_roles.each do |role|
        login role
        expect(page).to have_css(success, text: signed_in_as)
        visit new_admin_image_path
        expect(page).to_not have_css(failure)
        visit edit_admin_image_path(@image)
        expect(page).to_not have_css(failure)
        visit images_path
        click_link @image.id.to_s
        expect(page).to have_xpath(cell(caption), text: caption_text)
        expect(page).to have_link(button)
      end
    end

    it "other roles and guests can only view" do
      not_ok_roles.push("guest").each do |role|
        if role == "guest"
          logout
        else
          login role
          expect(page).to have_css(success, text: signed_in_as)
        end
        visit new_admin_image_path
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_image_path(@image)
        expect(page).to have_css(failure, text: unauthorized)
        visit images_path
        click_link @image.id.to_s
        expect(page).to have_xpath(cell(caption), text: caption_text)
        expect(page).to_not have_link(button)
      end
    end
  end

  context "create" do
    before(:each) do
      @user = login("editor")
      visit new_admin_image_path
    end

    it "jpeg" do
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

    it "gif" do
      fill_in caption, with: "Suzanne"
      fill_in year, with: "2004"
      fill_in credit, with: "Mark Orr"
      attach_file file, image_dir + "suzanne.gif"
      click_button save

      expect(page).to have_css(success, text: success_text)
      expect(Image.count).to eq 1
      image = Image.first

      expect(image.caption).to eq "Suzanne"
      expect(image.year).to eq 2004
      expect(image.credit).to eq "Mark Orr"
      expect(image.user_id).to eq @user.id
      expect_data_suzanne(image)
    end

    it "png" do
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
  end

  context "edit" do
    before(:each) do
      login("editor")
      visit new_admin_image_path
      fill_in caption, with: "April"
      fill_in year, with: "1986"
      fill_in credit, with: "Mark Orr"
      attach_file file, image_dir + "april.jpeg"
      click_button save
      expect(Image.count).to eq 1
      @image = Image.first
    end

    it "image data" do
      click_link edit
      attach_file file, image_dir + "gearoidin.png"
      click_button save

      @image.reload

      expect(@image.caption).to eq "April"
      expect(@image.year).to eq 1986
      expect(@image.credit).to eq "Mark Orr"
      expect_data_gearoidin(@image)
    end

    it "meta data" do
      click_link edit
      fill_in caption, with: "Suzanne"
      fill_in year, with: "2004"
      fill_in credit, with: "Gearóidín Uí Laighléis"
      click_button save

      @image.reload

      expect(@image.caption).to eq "Suzanne"
      expect(@image.year).to eq 2004
      expect(@image.credit).to eq "Gearóidín Uí Laighléis"
      expect_data_april(@image)
    end

    it "all data" do
      click_link edit
      fill_in caption, with: "Suzanne"
      fill_in year, with: "2002"
      fill_in credit, with: "Carey Wilman"
      attach_file file, image_dir + "suzanne.gif"
      click_button save

      @image.reload

      expect(@image.caption).to eq "Suzanne"
      expect(@image.year).to eq 2002
      expect(@image.credit).to eq "Carey Wilman"
      expect_data_suzanne(@image)
    end
  end
end
