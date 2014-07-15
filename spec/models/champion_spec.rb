require 'rails_helper'

describe Champion do
  context "winners" do
    let(:champion) { build(:champion) }

    context "valid" do
      it "normal names" do
        champion.winners = "M. J. L. Orr"
        expect(champion).to be_valid
        champion.winners = "M. J. L. Orr, E. Curin"
        expect(champion).to be_valid
      end

      it "O'" do
        champion.winners = "D. O'Siochru"
        expect(champion).to be_valid
        champion.winners = "D. O'Siochru, A. T. Delaney"
        expect(champion).to be_valid
        champion.winners = "B. O'Shaughnessy, D. O'Siochru"
        expect(champion).to be_valid
      end

      it "Mac" do
        champion.winners = "H. MacGrillen"
        expect(champion).to be_valid
      end

      it "hypenated" do
        champion.winners = "H. Lowry-O'Reilly"
        expect(champion).to be_valid
      end

      it "double barelled" do
        champion.winners = "A. Astaneh Lopez"
        expect(champion).to be_valid
        champion.winners = "A. Astaneh Lopez, M. Orr"
        expect(champion).to be_valid
      end
    end

    context "invalid" do
      let(:champion) { build(:champion) }

      it "initials only with full stops" do
        champion.winners = "MJLOrr"
        expect(champion).to_not be_valid
        champion.winners = "Mark Orr"
        expect(champion).to_not be_valid
      end

      it "apostrophes" do
        champion.winners = "D. O\"Siochru"
        expect(champion).to_not be_valid
      end

      it "double barelled" do
        champion.winners = "A. Astaneh/Lopez"
        expect(champion).to_not be_valid
      end
    end

    context "correct" do
      let(:champion) { build(:champion) }

      it "extra spaces" do
        champion.winners = " A.Astaneh  Lopez "
        expect(champion).to be_valid
        expect(champion.winners).to eq "A. Astaneh Lopez"
        champion.winners = " H.Lowry - O ' Reilly"
        expect(champion).to be_valid
        expect(champion.winners).to eq "H. Lowry-O'Reilly"
        champion.winners = "M.J.L.Orr,J.A.P.Rynd"
        expect(champion).to be_valid
        expect(champion.winners).to eq "M. J. L. Orr, J. A. P. Rynd"
      end

      it "wrong apostrophe" do
        champion.winners = "D. O`Siochru"
        expect(champion).to be_valid
        expect(champion.winners).to eq "D. O'Siochru"
        champion.winners = "D. O’ Siochru, G. O ‘Connell"
        expect(champion).to be_valid
        expect(champion.winners).to eq "D. O'Siochru, G. O'Connell"
      end

      it "missing full stops" do
        champion.winners = "D O'Siochru"
        expect(champion).to be_valid
        expect(champion.winners).to eq "D. O'Siochru"
      end

      it "capitalization" do
        champion.winners = "M. J. L. ORR, J. A. P. rynd"
        expect(champion).to be_valid
        expect(champion.winners).to eq "M. J. L. Orr, J. A. P. Rynd"
      end
    end
  end
end
