FactoryGirl.define do
  factory :upload do
    description "Chess Today #4000"
    year        2011
    access      "all"
    data        { File.new(Rails.root + "spec" + "files" + "uploads" + "CT-4000.pdf") }
    user
  end
end
