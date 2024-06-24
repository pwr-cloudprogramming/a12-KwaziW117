const url = `${window.location.protocol}//${window.location.hostname}:8080`;

let stompClient;
let gameId;
let playerType;

function connectToSocket(gameId) {
  console.log("connecting to the game");
  const idToken = localStorage.getItem("idToken");
  const socket = new SockJS(`${url}/gameplay`);
  stompClient = Stomp.over(socket);
  stompClient.connect(
    { Authorization: `Bearer ${idToken}` },
    function (frame) {
      console.log("connected to the frame: " + frame);
      stompClient.subscribe(
        "/topic/game-progress/" + gameId,
        function (response) {
          let data = JSON.parse(response.body);
          console.log(data);
          displayResponse(data);
          if (data.player2 && data.player2.login) {
            fetchProfilePics(data.player1.login, data.player2.login);
          }
        }
      );
    },
    function (error) {
      console.log("STOMP error: " + error);
    }
  );

  fetchProfilePics(
    document.getElementById("player-username").textContent,
    opponentUsername
  );
}

function create_game() {
  const idToken = localStorage.getItem("idToken");
  aws_amplify.Auth.currentAuthenticatedUser()
    .then((user) => {
      const login = user.username;
      $.ajax({
        url: url + "/game/start",
        type: "POST",
        headers: {
          Authorization: "Bearer " + idToken,
        },
        dataType: "json",
        contentType: "application/json",
        data: JSON.stringify({
          login: login,
        }),
        success: function (data) {
          gameId = data.gameId;
          playerType = "X";
          reset();
          connectToSocket(gameId);
          alert("You created a game. Game id is: " + data.gameId);
          gameOn = true;
        },
        error: function (error) {
          console.log(error);
        },
      });
    })
    .catch((err) => {
      console.log(err);
    });
}

function connectToRandom() {
  const idToken = localStorage.getItem("idToken");
  aws_amplify.Auth.currentAuthenticatedUser()
    .then((user) => {
      const login = user.username;
      $.ajax({
        url: url + "/game/connect/random",
        type: "POST",
        headers: {
          Authorization: "Bearer " + idToken,
        },
        dataType: "json",
        contentType: "application/json",
        data: JSON.stringify({
          login: login,
        }),
        success: function (data) {
          gameId = data.gameId;
          playerType = "O";
          reset();
          const opponentUsername = data.player1.login;
          connectToSocket(gameId, opponentUsername);
          alert("Congrats you're playing with: " + opponentUsername);
        },
        error: function (error) {
          console.log(error);
        },
      });
    })
    .catch((err) => {
      console.log(err);
    });
}

function connectToSpecificGame() {
  const gameId = document.getElementById("game_id").value;
  if (gameId == null || gameId === "") {
    alert("Please enter game id");
  } else {
    const idToken = localStorage.getItem("idToken");
    aws_amplify.Auth.currentAuthenticatedUser()
      .then((user) => {
        const login = user.username;
        $.ajax({
          url: url + "/game/connect",
          type: "POST",
          headers: {
            Authorization: "Bearer " + idToken,
          },
          dataType: "json",
          contentType: "application/json",
          data: JSON.stringify({
            player: {
              login: login,
            },
            gameId: gameId,
          }),
          success: function (data) {
            gameId = data.gameId;
            playerType = "O";
            reset();
            const opponentUsername = data.player1.login;
            connectToSocket(gameId, opponentUsername);
            alert("Congrats you're playing with: " + opponentUsername);
          },
          error: function (error) {
            console.log(error);
          },
        });
      })
      .catch((err) => {
        console.log(err);
      });
  }
}

async function fetchProfilePics(playerUsername, opponentUsername) {
  const idToken = localStorage.getItem("idToken");
  const url = `${window.location.protocol}//${window.location.hostname}:8080/api/get-profile-pic/${playerUsername}/${opponentUsername}`;
  try {
    const response = await fetch(url, {
      headers: {
        Authorization: "Bearer " + idToken,
      },
    });
    if (!response.ok) {
      throw new Error("Failed to fetch profile picture");
    }
    const data = await response.json();

    const player1PicBase64 = data.player1Pic;
    const player2PicBase64 = data.player2Pic;

    const player1Name = data.player1Name;
    const player2Name = data.player2Name;

    addFooter(player1PicBase64, player2PicBase64, player1Name, player2Name);
  } catch (error) {
    console.error("Error fetching profile pictures:", error);
  }
}

function addFooter(
  player1PicBase64,
  player2PicBase64,
  player1Name,
  player2Name
) {
  const footer = document.createElement("footer");
  footer.innerHTML = `
        <div id="player-info" style="display: flex; justify-content: space-around; align-items: center;">
            <div id="player1" style="text-align: center; color: white;">
                <img id="player1-pic" src="data:image/png;base64,${player1PicBase64}" alt="${player1Name}" width="100" height="100">
                <p id="player1-name">${player1Name}</p>
            </div>
            <div id="vs" style="text-align: center; color: white; font-size: 24px; margin: 0 20px;">VS</div>
            <div id="player2" style="text-align: center; color: white;">
                <img id="player2-pic" src="data:image/png;base64,${player2PicBase64}" alt="${player2Name}" width="100" height="100">
                <p id="player2-name">${player2Name}</p>
            </div>
        </div>
    `;
  const existingFooter = document.querySelector("#game-interface footer");
  if (existingFooter) {
    existingFooter.remove();
  }
  document.getElementById("game-interface").appendChild(footer);
}
