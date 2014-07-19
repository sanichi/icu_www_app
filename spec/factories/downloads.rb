FactoryGirl.define do
  factory :download do
    description "Chess Today #4000"
    year        2011
    access      "all"
    data        { File.new(Rails.root + "spec" + "files" + "downloads" + "CT-4000.pdf") }
    user
  end
end
