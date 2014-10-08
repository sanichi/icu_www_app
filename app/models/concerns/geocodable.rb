module Geocodable
  extend ActiveSupport::Concern

  included do
    before_validation :guess_geocodes
  end

  def guess_geocodes
    if lat.blank? || long.blank?
      case location
      when /auburn.+lodge.+hotel.+ennis/i
        self.lat  = 52.865436
        self.long = -8.980899
      when /benildus.+college.+stillorgan.+dublin/i
        self.lat  = 53.284804
        self.long = -6.221387
      when /boyne.+valley.+hotel.+drogheda/i
        self.lat  = 53.708573
        self.long = -6.314182
      when /(butler|club).+house.+kilkenny/i
        self.lat  = 52.6494160
        self.long = -7.2516630
      when /caleta.+hotel.+gibraltar/i
        self.lat  = 36.138306
        self.long = -5.341287
      when /carlton.+shearwater.+hotel.+ballinasloe/i
        self.lat  = 53.326461
        self.long = -8.219543
      when /corrib.+great.+southern.+galway/i
        self.lat  = 53.278550
        self.long = -9.006227
      when /castle.+hotel.+bunratty/i
        self.lat  = 52.69614
        self.long = -8.816272
      when /dunraven.+arms.+hotel.+adare/i
        self.lat  = 52.565697
        self.long = -8.786747
      when /esplanade.+hotel.+bray/i
        self.lat  = 53.199098
        self.long = -6.096285
      when /grand.+hotel.+wicklow/i
        self.lat  = 52.980893
        self.long = -6.047359
      when /gresham.+hotel.+connell.+dublin/i
        self.lat  = 53.351888
        self.long = -6.260601
      when /metropole.+hotel.+cork/i
        self.lat  = 51.901628
        self.long = -8.467355
      when /hilton.+airport.+(northern|malahide).+dublin/i
        self.lat  = 53.403653
        self.long = -6.179954
      when /(hilton.+kilmainham|kilmainham.+hilton).+dublin/i
        self.lat  = 53.342568
        self.long = -6.308072
      when /ierne.+club.+grace.*park.+dublin/i
        self.lat  = 53.368252
        self.long = -6.249739
      when /kilmurray.+lodge.+hotel.+limerick/i
        self.lat  = 52.668693
        self.long = -8.553940
      when /(limerick.+university|university.+limerick)/i
        self.lat  = 52.668739
        self.long = -8.574471
      when /menlo.+park.+galway/i
        self.lat  = 53.288164
        self.long = -9.046882
      when /methodist.+college.+belfast/i
        self.lat  = 54.583587
        self.long = -5.940221
      when /morrison.+hotel.+ormond.+dublin/i
        self.lat  = 53.346502
        self.long = -6.266048
      when /oige.+mountjoy.+dublin/i
        self.lat  = 53.356153
        self.long = -6.268251
      when /red.+cow.+moran.+dublin/i
        self.lat  = 53.319062
        self.long = -6.364891
      when /student.+union.+university.+belfast/i
        self.lat  = 54.585640
        self.long = -5.937101
      when /tara.+towers.+hotel.+booterstown/i
        self.lat  = 53.312600
        self.long = -6.201941
      when /teachers.+club.+parnell.+dublin/i
        self.lat  = 53.353324
        self.long = -6.265133
      when /west.+county.+ennis/i
        self.lat  = 52.831998
        self.long = -8.981091
      when /wynn.+hotel.+abbey.+dublin/i
        self.lat  = 53.348649
        self.long = -6.258743
      end
    end
  end
end
