class IcuController < ApplicationController
  (Global::ICU_PAGES.keys + %i[index]).each { |m| define_method(m) {} }
end
