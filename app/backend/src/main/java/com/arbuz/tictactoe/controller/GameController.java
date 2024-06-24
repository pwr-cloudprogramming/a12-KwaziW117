package com.arbuz.tictactoe.controller;

import com.amazonaws.services.dynamodbv2.AmazonDynamoDB;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder;
import com.amazonaws.services.dynamodbv2.document.DynamoDB;
import com.amazonaws.services.dynamodbv2.document.Item;
import com.amazonaws.services.dynamodbv2.document.PutItemOutcome;
import com.amazonaws.services.dynamodbv2.document.Table;
import com.arbuz.tictactoe.config.DynamoDBConfig;
import com.arbuz.tictactoe.exception.InvalidGameException;
import com.arbuz.tictactoe.exception.NotFoundException;
import com.arbuz.tictactoe.model.GamePlay;
import com.arbuz.tictactoe.controller.dto.ConnectRequest;
import com.arbuz.tictactoe.exception.InvalidParamException;
import com.arbuz.tictactoe.model.Game;
import com.arbuz.tictactoe.model.GameStatus;
import com.arbuz.tictactoe.model.Player;
import com.arbuz.tictactoe.service.GameService;
import com.arbuz.tictactoe.storage.GameRepository;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.*;

@RestController
@Slf4j
@AllArgsConstructor
@RequestMapping("/game")
@CrossOrigin(origins = "*")
public class GameController {
    private final GameService gameService;
    private final SimpMessagingTemplate simpMessagingTemplate;
    private final GameRepository gameRepository;
    private final DynamoDBConfig client;

    @PostMapping("/start")
    public ResponseEntity<Game> start(@RequestBody Player player) {
        log.info("start game request: {}", player);
        return ResponseEntity.ok(gameService.createGame(player));
    }

    @PostMapping("/connect")
    public ResponseEntity<Game> connect(@RequestBody ConnectRequest request) throws InvalidParamException, InvalidGameException {
        log.info("connect request: {}", request);
        Game game = gameService.connectToGame(request.getPlayer(), request.getGameId());
        if (game != null) {
            notifyPlayers(game);
        }
        return ResponseEntity.ok(game);
    }

    @PostMapping("/connect/random")
    public ResponseEntity<Game> connectRandom(@RequestBody Player player) throws NotFoundException {
        log.info("connect random {}", player);
        Game game = gameService.connectToRandomGame(player);
        if (game != null) {
            notifyPlayers(game);
        }
        return ResponseEntity.ok(game);
    }

    @PostMapping("/gameplay")
    public ResponseEntity<Game> gamePlay(@RequestBody GamePlay request) throws NotFoundException, InvalidGameException {
        log.info("gameplay: {}", request);
        Game game = gameService.gamePlay(request);
        simpMessagingTemplate.convertAndSend("/topic/game-progress/" + game.getGameId(), game);
        if (game.getStatus() == GameStatus.FINISHED) {
            //saveGame(game);
            DynamoDB dynamoDB = new DynamoDB(client.amazonDynamoDB());
            Table table = dynamoDB.getTable(client.getTableName());

            Item item = new Item()
                    .withPrimaryKey("GameId", game.getGameId())
                    .withString("Player1", game.getPlayer1().getLogin())
                    .withString("Player2", game.getPlayer2().getLogin());

            if (game.getWinner() != null) {
                item.withString("Winner", String.valueOf(game.getWinner().getValue()));
            } else {
                item.withString("Winner", "0");
            }

            PutItemOutcome outcome = table.putItem(item);
            log.info(outcome.getPutItemResult().toString());
        }
        return ResponseEntity.ok(game);
    }

    private void notifyPlayers(Game game) {
        simpMessagingTemplate.convertAndSend("/topic/game-progress/" + game.getGameId(), game);
    }

    private void saveGame(Game game) {
        gameRepository.saveGame(game);
    }
}
