var turns = [["#", "#", "#"], ["#", "#", "#"], ["#", "#", "#"]];
var turn = "";
var gameOn = false;

function playerTurn(turn, id) {
    if (gameOn) {
        var spotTaken = $("#" + id).text();
        if (spotTaken === "#") {
            makeAMove(playerType, id.split("_")[0], id.split("_")[1]);
        }
    }
}

function makeAMove(type, xCoordinate, yCoordinate) {
    const idToken = localStorage.getItem('idToken');
    $.ajax({
        url: url + "/game/gameplay",
        type: 'POST',
        headers: {
            'Authorization': `Bearer ${idToken}`
        },
        dataType: "json",
        contentType: "application/json",
        data: JSON.stringify({
            "type": type,
            "coordinateX": xCoordinate,
            "coordinateY": yCoordinate,
            "gameId": gameId
        }),
        success: function (data) {
            gameOn = false;
            displayResponse(data);
        },
        error: function (error) {
            console.log(error);
        }
    });
}

function displayResponse(data) {
    let board = data.board;
    for (let i = 0; i < board.length; i++) {
        for (let j = 0; j < board[i].length; j++) {
            if (board[i][j] === 1) {
                turns[i][j] = 'X';
            } else if (board[i][j] === 2) {
                turns[i][j] = 'O';
            }
            let id = i + "_" + j;
            $("#" + id).text(turns[i][j]);
        }
    }
    if (data.winner != null) {
        alert("Winner is " + data.winner);
        updateRankings(data.winner, data.player1.login, data.player2.login);
    }
    gameOn = true;
}

function updateRankings(winner, player1, player2) {
    const idToken = localStorage.getItem('idToken');
    let result;
    if (winner === 'X') {
        result = 1;
    } else if (winner === 'O') {
        result = 2;
    } else {
        result = 0;
    }

    $.ajax({
        url: apiGatewayUrl + "/results",
        type: 'POST',
        headers: {
            'Authorization': `Bearer ${idToken}`
        },
        dataType: "json",
        contentType: "application/json",
        data: JSON.stringify({
            "gameId": gameId,
            "player1": player1,
            "player2": player2,
            "winner": result
        }),
        success: function (data) {
            console.log("Rankings updated successfully");
        },
        error: function (error) {
            console.log("Error updating rankings: ", error);
        }
    });
}

$(".tic").click(function () {
    var slot = $(this).attr('id');
    playerTurn(turn, slot);
});

function reset() {
    turns = [["#", "#", "#"], ["#", "#", "#"], ["#", "#", "#"]];
    $(".tic").text("#");
}

$("#reset").click(function () {
    reset();
});
