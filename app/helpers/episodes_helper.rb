module EpisodesHelper
  def episode_number_menu(number)
    numbers = (1..number).map{ |n| [n, n] }
    options_for_select(numbers, number)
  end
end
