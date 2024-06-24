package com.arbuz.tictactoe.controller.dto;

import com.arbuz.tictactoe.model.Player;
import lombok.Data;

@Data
public class ConnectRequest {
    private Player player;
    private String gameId;
}
