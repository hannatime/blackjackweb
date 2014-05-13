require 'rubygems'
require 'sinatra'


set :sessions, true

# -------------
# -------------
# ------------- helper methods
# -------------
# -------------

helpers do
  
  def calculate_total(cards)
   arr = cards.map{|e| e[1] }

  total = 0
  arr.each do |value|
    if value == 'A'
      total += 11

    elsif value.to_i == 0
      total += 10
    else
      total += value.to_i
    end
  end
  
  arr.select{|e| e == 'A'}.count.times do
    total -= 10 if total > @win_number
  end

  total
  end

  def new_deck
    session[:deck] = []
    suits = ['H', 'D', 'S', 'C']
    cards = ['2','3', '4', '5', '6','7', '8', '9', '10', 'J', 'Q', 'K', 'A']
    session[:deck] = suits.product(cards)
    session[:deck].shuffle!
  end
#
  def win_lose_draw
    player_total = calculate_total(session[:player_cards])
    dealer_total = calculate_total(session[:dealer_cards])
    
    if player_total == @win_number && @stay == false
        @show_hit_or_stay_buttons = false
        @winner = "You got Blackjack, you win!!"
        @win = true
        bet_calc
    elsif player_total > @win_number && @stay == false
        @loser = "Sorry you busted!"
        @show_hit_or_stay_buttons = false
        @lose = true
        bet_calc
    elsif dealer_total > @win_number && @stay == false
        @winner = "The dealer busted you win!"
        @show_hit_or_stay_buttons = false
        @win = true
        bet_calc
    elsif @stay
        if dealer_total > @win_number
          @winner = "The dealer busted you win!"
          @show_hit_or_stay_buttons = false
          @win = true
          bet_calc
        elsif player_total > @win_number
          @loser = "Sorry you busted!"
          @show_hit_or_stay_buttons = false
          @lose = true
          bet_calc
        elsif dealer_total == @win_number
          @loser = "The dealer got Blackjack, you lose!!"
          @lose = true
          bet_calc
          @show_hit_or_stay_buttons = false
        elsif player_total > dealer_total
          @winner = "You have #{player_total}, the dealer has #{dealer_total}, you win"
          @show_hit_or_stay_buttons = false
          @win = true
          bet_calc
        elsif player_total < dealer_total
          @loser = "You have #{player_total}, the dealer has #{dealer_total}, you lose"
          @show_hit_or_stay_buttons = false
          @lose = true
          bet_calc
        elsif player_total == dealer_total
          @loser = "You have #{player_total}, the dealer has #{dealer_total}, it's a draw"
          @show_hit_or_stay_buttons = false
          @play_again = true
        end
    end 
  end

  def bet_calc
    if @win == true
      session[:player_account] += session[:bet_amount].to_i
      @show_player_account = true
      @play_again = true    
    elsif @lose == true
      session[:player_account] -= session[:bet_amount].to_i
      @show_player_account = true
      @play_again = true 
    end
  end
 
 def card_image(card)
   suit = case card[0]
          when 'H' then 'hearts'
          when 'D' then 'diamonds'
          when 'C' then 'clubs'
          when 'S' then 'spades'
  end
  
  value = card[1]
  if ['J', 'Q', 'K', 'A'].include?(value)
    value = case card[1]
            when 'J' then 'jack'
            when 'Q' then 'queen'
            when 'K' then 'king'
            when 'A' then 'ace'
          end
        end
 
  "<img src='/images/cards2/#{value}_of_#{suit}.png' class = 'card_image'>"
 end

end

before do
@stay = false
@show_hit_or_stay_buttons = true
@dealers_turn_button = false
@new_game_button = false
@new_player_button = true
@show_player_account = false
@win = false
@lose = false
@time_to_bet = false
@show_everything = true
@play_again = false
@win_number = 21
@bank = true
@winner = false
@loser = false
end
# -------------
# -------------
# ------------- pages
# -------------
# -------------

# ------------- default route
get '/' do
  if session[:player_name]
    redirect '/bet'
  else
    redirect '/set_name'
  end
end

# ------------- landing page
get '/landing' do
  erb :landing, :layout => false
end

# ------------- profile page
get '/profile' do
  erb :"/users/set_name"
end

# ------------- bet page
get '/bet' do 
  @new_game_button = false
  @bank = false
  erb :bet
end

# ------------- setname page
get '/set_name' do
session[:player_account] = 500
@new_game_button = false
@new_player_button = false
@bank = false
erb :"/players/set_name"
end

# ------------- game page
get '/game' do
new_deck
@new_game_button = true
session[:player_cards] = []
session[:dealer_cards] = []
session[:player_cards] << session[:deck].pop
session[:dealer_cards] << session[:deck].pop
session[:player_cards] << session[:deck].pop
session[:dealer_cards] << session[:deck].pop
  if calculate_total(session[:player_cards]) == @win_number
    @success = "You got Blackjack, you win!!"
    @show_hit_or_stay_buttons = false
  end
erb :game
end

# ------------- cards route page
get '/images/cards/' do

end
# -------------
# -------------
# ------------- posts
# -------------
# -------------

# ------------- bet post 
post '/bet' do
  if params[:bet_amount].empty?
    @error = "You need to bet to play"
    halt erb(:bet)
  elsif
    params[:bet_amount].to_i < 1
    @error = "Minimum bet is $1"
    halt erb(:bet)
    elsif
    params[:bet_amount].to_i > session[:player_account]
    @error = "You don't have enough money, reduce your bet"
    halt erb(:bet)
  end
  session[:bet_amount] = params[:bet_amount] 
  redirect :game
end

# ------------- hit post
post '/hit' do
  
  if session[:deck].count < 8 
      new_deck
  end

  if session[:player_cards].count < 5
    session[:player_cards] << session[:deck].pop
    win_lose_draw
    @new_player_button = true
    @new_game_button = true
  else 
    @show_hit_or_stay_buttons = false
    @new_game_button = true
    @new_player_button = true
    @new_game_button = true
    @show_hit_or_stay_buttons = false
    @stay = true
    
    while calculate_total(session[:dealer_cards]) < 17 && session[:dealer_cards].count < 5
      session[:dealer_cards] << session[:deck].pop
    end

    win_lose_draw
  end
  
  erb :game, layout: false
end

# ------------- stay post
post '/stay' do
   @success = "You have chosen to stay, click next for the dealers turn"
   @show_hit_or_stay_buttons = false
   @dealer_turn_button = true
   @new_game_button = true
   win_lose_draw
   erb :game, layout: false
end

post '/dealer_turn' do
  @new_game_button = true
  @show_hit_or_stay_buttons = false

  while calculate_total(session[:dealer_cards]) < 17 && session[:dealer_cards].count < 5
    session[:dealer_cards] << session[:deck].pop
   end
  @stay = true
  win_lose_draw

  erb :game, layout: false
end

# ------------- setname post
post '/set_name' do
  if params[:player_name].empty?
    @error = "You need a name to play"
    @new_player_button = false
    @bank = false
    halt erb(:"/players/set_name")
  end
  session[:player_name] = params[:player_name].capitalize
  redirect '/bet'
end


# ------------- new game post
post '/new_game' do
  @new_game_button = true
  
  if session[:deck].count < 10 
      new_deck
  end

  session[:player_cards].clear
  session[:dealer_cards].clear
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  @stay = false
  win_lose_draw
  @time_to_bet = true
  @show_player_account = true
  session[:bet_amount].clear
 
  if session[:player_account] <= 0
    @error = "You're broke, go get a loan"
    @new_game_button = false
    @new_player_button = true
    @time_to_bet = false
    @show_player_account = false
    @show_hit_or_stay_buttons = false
    @show_everything = false
    erb :game
  end

  redirect '/bet'
end


# ------------- new player post
post '/new_player' do
  session.clear
  @new_player_button = false
  @bank = false
  redirect '/set_name'
end