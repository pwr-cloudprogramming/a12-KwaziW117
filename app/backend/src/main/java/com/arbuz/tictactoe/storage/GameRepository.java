package com.arbuz.tictactoe.storage;

import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBMapper;
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBSaveExpression;
import com.amazonaws.services.dynamodbv2.model.AttributeValue;
import com.amazonaws.services.dynamodbv2.model.ExpectedAttributeValue;
import com.arbuz.tictactoe.config.DynamoDBConfig;
import com.arbuz.tictactoe.model.Game;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

@Repository
public class GameRepository {

    private final DynamoDBMapper dynamoDBMapper;
    private final String tableName;

    @Autowired
    public GameRepository(DynamoDBMapper dynamoDBMapper, DynamoDBConfig config) {
        this.dynamoDBMapper = dynamoDBMapper;
        this.tableName = config.getTableName();
    }

    public void saveGame(Game game) {
        dynamoDBMapper.save(game, new DynamoDBSaveExpression().withExpectedEntry("GameId",
                new ExpectedAttributeValue(new AttributeValue().withS(game.getGameId()))));
    }
}
