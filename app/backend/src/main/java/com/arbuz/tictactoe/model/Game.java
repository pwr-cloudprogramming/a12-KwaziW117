package com.arbuz.tictactoe.model;

import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBHashKey;
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBTable;
import lombok.Data;

@Data
@DynamoDBTable(tableName = "TicTacToeGame")
public class Game {
    @DynamoDBHashKey(attributeName = "GameId")
    private String gameId;
    private Player player1;
    private Player player2;
    private GameStatus status;
    private int[][] board;
    private TicToe winner;
}
