require 'rails_helper'

describe Expandable do
  let(:d)      { Class.new{ include Expandable }.new }
  let(:bad_id) { 99 }

  def error(obj, atr: "ID", data: bad_id)
    if data && atr
      "#{data} is not a valid #{obj} #{atr}"
    else
      obj
    end
  end

  context "articles" do
    let(:article) { create(:article) }
    let(:title) { Faker::Lorem.sentence }
    let(:link)  { '<a href="/articles/%d">%s</a>' }

    it "default title" do
      expect(d.expand_all("[ART:#{article.id}]")).to eq link % [article.id, article.title]
    end

    it "explicit title" do
      expect(d.expand_all("[ART:#{article.id}:title=#{title}]")).to eq link % [article.id, title]
    end

    it "implicit title" do
      expect(d.expand_all("[ART:#{article.id}:#{title}]")).to eq link % [article.id, title]
    end

    it "invalid ID" do
      expect{d.expand_all("[ART:#{bad_id}]")}.to raise_error error("article")
    end
  end

  context "boards" do
    let(:fen)     { "k7/8/8/8/8/8/8/7K w" }
    let(:nef)     { "k7/8/8/8/8/8/8/7K b" }
    let(:style)   { "hce30png" }
    let(:comment) { "White to play and mate in 3" }

    it "defaults" do
      result = d.expand_all("[FEN:#{fen}]")
      expect(result).to match /\A<table class="board float-left right-margin #{style}">/
      expect(result).to match /<th colspan="8" class="comment small" width="240">⇧<\/th>/
    end

    it "black to move" do
      result = d.expand_all("[FEN:#{nef}]")
      expect(result).to match /<th colspan="8" class="comment small" width="240">⬇︎<\/th>/
    end

    it "left align" do
      result = d.expand_all("[FEN:#{fen}:align=left]")
      expect(result).to match /\A<table class="board float-left right-margin #{style}">/
    end

    it "right align" do
      result = d.expand_all("[FEN:#{fen}:align=right]")
      expect(result).to match /\A<table class="board float-right left-margin #{style}">/
    end

    it "centered" do
      result = d.expand_all("[FEN:#{fen}:align=center]")
      expect(result).to match /\A<table class="board float-center #{style}">/
    end

    it "comment" do
      result = d.expand_all("[FEN:#{fen}:comment=#{comment}]")
      expect(result).to match /<th colspan="8" class="comment small" width="240">⇧ #{comment}<\/th>/
    end

    it "comment and alignment" do
      result = d.expand_all("[FEN:#{fen}:align=right:comment=#{comment}]")
      expect(result).to match /\A<table class="board float-right left-margin #{style}">/
      expect(result).to match /<th colspan="8" class="comment small" width="240">⇧ #{comment}<\/th>/
    end

    it "invalid FEN" do
      expect{d.expand_all("[FEN:rubbish]")}.to raise_error error("invalid board position", data: nil)
    end
  end

  context "emails" do
    it "text" do
      expect(d.expand_all("[EMA:ratings@icu.ie:Rating Officer]")).to eq %q{<script>liame('vr">Engvat Bssvpre<\057n>', '<n uers="znvygb:engvatf\100vph')</script>}
    end

    it "no text" do
      expect(d.expand_all("[EMA:secretary@icu.ie]")).to eq %q{<script>liame('vr<\057n>', 'vr">frpergnel\100vph', '<n uers="znvygb:frpergnel\100vph')</script>}
    end

    it "invalid email" do
      expect{d.expand_all("[EMA:chairman.icu.ie]")}.to raise_error error("email", atr: "address", data: "chairman.icu.ie")
    end
  end

  context "events" do
    let(:event) { create(:event) }
    let(:name)  { Faker::Lorem.sentence }
    let(:link)  { '<a href="/events/%d">%s</a>' }

    it "default name" do
      expect(d.expand_all("[EVT:#{event.id}]")).to eq  link % [event.id, event.name]
    end

    it "explicit name" do
      expect(d.expand_all("[EVT:#{event.id}:name=#{name}]")).to eq link % [event.id, name]
    end

    it "implicit name" do
      expect(d.expand_all("[EVT:#{event.id}:#{name}]")).to eq link % [event.id, name]
    end

    it "backward compatibility" do
      expect(d.expand_all("[EVT:#{event.id}:title=#{name}]")).to eq link % [event.id, name]
    end

    it "invalid ID" do
      expect{d.expand_all("[EVT:#{bad_id}]")}.to raise_error error("event")
    end
  end

  context "games" do
    let(:game) { create(:game) }
    let(:text) { Faker::Lorem.sentence }
    let(:link) { '<a href="/games/%d">%s</a>' }

    %w[GME PGN].each do |type|
      context type do
        it "default text" do
          expect(d.expand_all("[#{type}:#{game.id}]")).to eq link % [game.id, "#{game.white}—#{game.black}"]
        end

        it "explicit text" do
          expect(d.expand_all("[#{type}:#{game.id}:text=#{text}]")).to eq link % [game.id, text]
        end

        it "implicit text" do
          expect(d.expand_all("[#{type}:#{game.id}:#{text}]")).to eq link % [game.id, text]
        end

        it "explicit result text" do
          expect(d.expand_all("[#{type}:#{game.id}:text=*-*]")).to eq link % [game.id, game.result]
        end

        it "implicit result text" do
          expect(d.expand_all("[#{type}:#{game.id}:*-*]")).to eq link % [game.id, game.result]
        end

        it "invalid ID" do
          expect{d.expand_all("[#{type}:#{bad_id}]")}.to raise_error error("game")
        end
      end
    end
  end

  context "image links" do
    let(:image) { create(:image) }
    let(:text)  { Faker::Lorem.sentence }
    let(:link)  { '<a href="/images/%d">%s</a>' }

    it "default text" do
      expect(d.expand_all("[IML:#{image.id}]")).to eq link % [image.id, "image"]
    end

    it "explicit text" do
      expect(d.expand_all("[IML:#{image.id}:text=#{text}]")).to eq link % [image.id, text]
    end

    it "implicit text" do
      expect(d.expand_all("[IML:#{image.id}:#{text}]")).to eq link % [image.id, text]
    end

    it "invalid ID" do
      expect{d.expand_all("[IML:#{bad_id}]")}.to raise_error error("image")
    end
  end

  context "images" do
    let(:image)  { create(:image) }
    let(:alt)    { Faker::Lorem.sentence }
    let(:fleft)  { "float-left" }
    let(:fright) { "float-right" }
    let(:mleft)  { "left-margin" }
    let(:mright) { "right-margin" }

    it "defaults" do
      result = d.expand_all("[IMG:#{image.id}]")
      expect(result).to match /\A<img src="[^"]+" width="[^"]+" height="[^"]+" class="[^"]+" alt="[^"]+">\z/
      expect(result).to match /src="#{Regexp.escape(image.data.url)}"/
      expect(result).to match /width="#{image.width}"/
      expect(result).to match /height="#{image.height}"/
      expect(result).to match /class="#{fleft} #{mright}"/
      expect(result).to match /alt="#{Regexp.escape(image.caption)}"/
    end

    it "scaled width" do
      width = image.width / 2
      height = ((width.to_f / image.width) * image.height).ceil
      result = d.expand_all("[IMG:#{image.id}:width=#{width}]")
      expect(result).to match /width="#{width}"/
      expect(result).to match /height="#{height}"/
    end

    it "scaled height" do
      height = image.height * 3
      width = ((height.to_f / image.height) * image.width).ceil
      result = d.expand_all("[IMG:#{image.id}:height=#{height}]")
      expect(result).to match /width="#{width}"/
      expect(result).to match /height="#{height}"/
    end

    it "custom width and height" do
      height = image.height - 10
      width = image.width + 10
      result = d.expand_all("[IMG:#{image.id}:width=#{width}:height=#{height}]")
      expect(result).to match /width="#{width}"/
      expect(result).to match /height="#{height}"/
    end

    it "explicit align left" do
      result = d.expand_all("[IMG:#{image.id}:align=left]")
      expect(result).to match /class="#{fleft} #{mright}"/
    end

    it "implicit align left" do
      result = d.expand_all("[IMG:#{image.id}:left]")
      expect(result).to match /class="#{fleft} #{mright}"/
    end

    it "explicit align right" do
      result = d.expand_all("[IMG:#{image.id}:align=right]")
      expect(result).to match /class="#{fright} #{mleft}"/
    end

    it "implicit align right" do
      result = d.expand_all("[IMG:#{image.id}:right]")
      expect(result).to match /class="#{fright} #{mleft}"/
    end

    it "explicit align center" do
      result = d.expand_all("[IMG:#{image.id}:align=center]")
      expect(result).to_not match /class=/
      expect(result).to match /\A<center><img[^>]+><\/center>\z/
    end

    it "implicit align center" do
      result = d.expand_all("[IMG:#{image.id}:center]")
      expect(result).to_not match /class=/
      expect(result).to match /\A<center><img[^>]+><\/center>\z/
    end

    it "explicit alt" do
      result = d.expand_all("[IMG:#{image.id}:alt=#{alt}]")
      expect(result).to match /alt="#{Regexp.escape(alt)}"/
    end

    it "implicit alt" do
      result = d.expand_all("[IMG:#{image.id}:#{alt}]")
      expect(result).to match /alt="#{Regexp.escape(alt)}"/
    end

    it "explicit margin on" do
      result = d.expand_all("[IMG:#{image.id}:margin=yes]")
      expect(result).to match /class="#{fleft} #{mright}"/
    end

    it "implicit margin on" do
      result = d.expand_all("[IMG:#{image.id}:yes]")
      expect(result).to match /class="#{fleft} #{mright}"/
    end

    it "explicit margin off" do
      result = d.expand_all("[IMG:#{image.id}:margin:no]")
      expect(result).to match /class="#{fleft}"/
    end

    it "implicit margin off" do
      result = d.expand_all("[IMG:#{image.id}:no]")
      expect(result).to match /class="#{fleft}"/
    end

    it "invalid ID" do
      expect{d.expand_all("[IML:#{bad_id}]")}.to raise_error error("image")
    end
  end

  context "news" do
    let(:news) { create(:news) }
    let(:text) { Faker::Lorem.sentence }
    let(:link)  { '<a href="/news/%d">%s</a>' }

    it "default text" do
      expect(d.expand_all("[NWS:#{news.id}]")).to eq link % [news.id, news.headline]
    end

    it "explicit text" do
      expect(d.expand_all("[NWS:#{news.id}:text=#{text}]")).to eq link % [news.id, text]
    end

    it "implicit text" do
      expect(d.expand_all("[NWS:#{news.id}:#{text}]")).to eq link % [news.id, text]
    end

    it "invalid ID" do
      expect{d.expand_all("[NWS:#{bad_id}]")}.to raise_error error("news")
    end
  end

  context "rated tournaments" do
    let(:text) { Faker::Lorem.sentence }
    let(:id)   { 100 }
    let(:link) { %q{<a href="http://ratings.icu.ie/tournaments/%d" target="ratings">%s</a>} }

    it "default text" do
      expect(d.expand_all("[RTN:#{id}]")).to eq  link % [id, id]
    end

    it "explicit text" do
      expect(d.expand_all("[RTN:#{id}:text=#{text}]")).to eq link % [id, text]
    end

    it "implicit text" do
      expect(d.expand_all("[RTN:#{id}:#{text}]")).to eq link % [id, text]
    end

    it "invalid ID" do
      expect{d.expand_all("[RTN:rubbish]")}.to raise_error error("rated tournament", data: "rubbish")
    end
  end

  context "tournaments" do
    let(:tournament) { create(:tournament) }
    let(:name)       { Faker::Lorem.sentence }
    let(:link)       { '<a href="/tournaments/%d">%s</a>' }

    it "default title" do
      expect(d.expand_all("[TRN:#{tournament.id}]")).to eq  link % [tournament.id, tournament.name]
    end

    it "explicit title" do
      expect(d.expand_all("[TRN:#{tournament.id}:name=#{name}]")).to eq link % [tournament.id, name]
    end

    it "implicit title" do
      expect(d.expand_all("[TRN:#{tournament.id}:#{name}]")).to eq link % [tournament.id, name]
    end

    it "backward compatibility" do
      expect(d.expand_all("[TRN:#{tournament.id}:title=#{name}]")).to eq link % [tournament.id, name]
    end

    it "invalid ID" do
      expect{d.expand_all("[TRN:#{bad_id}]")}.to raise_error error("tournament")
    end
  end

  context "uploads" do
    let(:upload) { create(:upload) }
    let(:text)   { Faker::Lorem.sentence }
    let(:link)   { '<a href="/uploads/%d">%s</a>' }

    it "default text" do
      expect(d.expand_all("[UPL:#{upload.id}]")).to eq link % [upload.id, "upload"]
    end

    it "explicit text" do
      expect(d.expand_all("[UPL:#{upload.id}:text=#{text}]")).to eq link % [upload.id, text]
    end

    it "implicit text" do
      expect(d.expand_all("[UPL:#{upload.id}:#{text}]")).to eq link % [upload.id, text]
    end

    it "invalid ID" do
      expect{d.expand_all("[UPL:#{bad_id}]")}.to raise_error error("upload")
    end
  end

  context "multiple" do
    let(:image)   { create(:image) }
    let(:article) { create(:article) }

    it "expansions" do
      text = "See [ART:#{article.id}:here] and\n[IML:#{image.id}:here].\n"
      expect(d.expand_all(text)).to match /\ASee <a href="[^"]+">here<\/a> and\n<a href="[^"]+">here<\/a>.\n\z/
    end
  end
end
