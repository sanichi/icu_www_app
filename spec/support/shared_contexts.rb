shared_context "features" do
  let(:active)       { I18n.t("active") }
  let(:address)      { I18n.t("address") }
  let(:city)         { I18n.t("city") }
  let(:confirm)      { I18n.t("confirm") }
  let(:delete)       { I18n.t("delete") }
  let(:description)  { I18n.t("description") }
  let(:details)      { I18n.t("details") }
  let(:edit)         { I18n.t("edit") }
  let(:either)       { I18n.t("either") }
  let(:email)        { I18n.t("email") }
  let(:file)         { I18n.t("file") }
  let(:icu)          { I18n.t("icu") }
  let(:inactive)     { I18n.t("inactive") }
  let(:last_search)  { I18n.t("last_search") }
  let(:member)       { I18n.t("member") }
  let(:name)         { I18n.t("name") }
  let(:notes)        { I18n.t("notes") }
  let(:please)       { I18n.t("please_select") }
  let(:save)         { I18n.t("save") }
  let(:search)       { I18n.t("search") }
  let(:season)       { I18n.t("season") }
  let(:signed_in_as) { I18n.t("session.signed_in_as") }
  let(:type)         { I18n.t("type") }
  let(:unauthorized) { I18n.t("unauthorized.default") }
  let(:year)         { I18n.t("year") }

  let(:failure)     { "div.alert-danger" }
  let(:field_error) { "div.help-block" }
  let(:success)     { "div.alert-success" }
  let(:warning)     { "div.alert-warning" }

  let(:created) { "successfully created" }
  let(:deleted) { "successfully deleted" }
  let(:updated) { "successfully updated" }

  let(:force_submit) { "\n" }
end