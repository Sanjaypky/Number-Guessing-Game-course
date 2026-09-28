#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USERNAME

USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."

  $PSQL "INSERT INTO users(username, games_played) VALUES('$USERNAME', 0)" > /dev/null

  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")

  GAMES_PLAYED=0
  BEST_GAME=""
else
  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"

  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

NUMBER_OF_GUESSES=0

echo "Guess the secret number between 1 and 1000:"

while true
do
  read GUESS

  if ! [[ $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  ((NUMBER_OF_GUESSES++))

  if [[ $GUESS -eq $SECRET_NUMBER ]]
  then
    break
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

$PSQL "INSERT INTO games(user_id, guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)" > /dev/null

NEW_GAMES_PLAYED=$((GAMES_PLAYED + 1))

if [[ -z $BEST_GAME || $BEST_GAME == "NULL" || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]
then
  $PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED, best_game=$NUMBER_OF_GUESSES WHERE user_id=$USER_ID" > /dev/null
else
  $PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED WHERE user_id=$USER_ID" > /dev/null
fi