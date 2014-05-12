require 'rubygems'
require 'sinatra'
require 'sinatra/contrib/all'
require 'pry'

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
    total -= 10 if total > 21
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
    
    if player_total == 21 && @stay == false
      @success = "You got Blackjack, you win!!"
      @show_hit_or_stay_buttons = false
      @win = true
      bet_calc
    elsif player_total > 21 && @stay == false
      @error = "Sorry you busted!"
      @show_hit_or_stay_buttons = false
      @lose = true
      bet_calc
    elsif dealer_total > 21 && @stay == false
      @error = "The dealer busted you win!"
      @show_hit_or_stay_buttons = false
      @win = true
      bet_calc
    elsif @stay
        if dealer_total > 21
        @error = "The dealer busted you win!"
        @show_hit_or_stay_buttons = false
        @win = true
        bet_calc
        elsif player_total > 21
        @error = "Sorry you busted!"
        @show_hit_or_stay_buttons = false
        @lose = true
        bet_calc
        elsif dealer_total == 21
        @error = "The dealer got Blackjack, you lose!!"
        @lose = true
        bet_calc
        @show_hit_or_stay_buttons = false
        elsif player_total > dealer_total
        @success = "You have #{player_total}, the dealer has #{dealer_total}, you win"
        @show_hit_or_stay_buttons = false
        @win = true
        bet_calc
        elsif player_total < dealer_total
        @error = "You have #{player_total}, the dealer has #{dealer_total}, you lose"
        @show_hit_or_stay_buttons = false
        @lose = true
        bet_calc
        elsif player_total == dealer_total
        @error = "You have #{player_total}, the dealer has #{dealer_total}, it's a draw"
        @show_hit_or_stay_buttons = false
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
@new_game_button = true
@new_player_button = true
@show_player_account = false
@win = false
@lose = false
@time_to_bet = false
@show_everything = true
@play_again = false
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
  erb :bet
end

# ------------- setname page
get '/set_name' do
session[:player_account] = 500
@new_game_button = false
@new_player_button = false
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
  if calculate_total(session[:player_cards]) == 21
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

post '/bet2' do
  if params[:bet_amount].empty?
    @error = "No bet to change, add a bet"
    @time_to_bet = true
    @show_player_account = true
    halt erb(:game)
  elsif
    params[:bet_amount].to_i < 1
    @error = "The minimum bet is $1"
    @time_to_bet = true
    @show_player_account = true
    halt erb(:game)
  elsif 
    params[:bet_amount].to_i > session[:player_account]
    @error = "You don't have enough money, reduce your bet"
    @show_player_account = true
    @time_to_bet = true
    halt erb(:game)
  end
  session[:bet_amount] = params[:bet_amount] 
  erb :game
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
   erb :game
   end

   erb :game
   
end

# ------------- stay post
post '/stay' do
   @success = "You have chosen to stay, click next for the dealers turn"
   @show_hit_or_stay_buttons = false
   @dealer_turn_button = true
   @new_game_button = true
   win_lose_draw
   erb :game
end

post '/dealer_turn' do
  @new_game_button = true
  @show_hit_or_stay_buttons = false
  @stay = true
  while calculate_total(session[:dealer_cards]) < 17 && session[:dealer_cards].count < 5
    session[:dealer_cards] << session[:deck].pop
   end
   win_lose_draw
   erb :game
end

# ------------- setname post
post '/set_name' do
  if params[:player_name].empty?
    @error = "You need a name to play"
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
erb :game
end


# ------------- new player post
post '/new_player' do
  session.clear
  @new_player_button = false
  redirect '/set_name'
end