FactoryGirl.define do
  factory :image do
    caption "Fractal"
    credit  "Mark Orr"
    year    2014
    data    { File.new(Rails.root + "spec" + "files" + "images" + "fractal.jpg") }
    user

    factory :image_april do
      caption "April Cronin, Dubai, UAE"
      year    1986
      data    { File.new(Rails.root + "spec" + "files" + "images" + "april.jpeg") }
    end

    factory :image_suzanne do
      caption "Suzanne Connolly"
      year    2000
      data    { File.new(Rails.root + "spec" + "files" + "images" + "suzanne.gif") }
      credit  "サナナイチ"
    end

    factory :image_gearoidin do
      caption "Gearóidín Uí Laighléis"
      year    2000
      data    { File.new(Rails.root + "spec" + "files" + "images" + "gearoidin.png") }
      credit  nil
    end
  end
end
