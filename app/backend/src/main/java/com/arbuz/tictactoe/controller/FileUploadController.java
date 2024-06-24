package com.arbuz.tictactoe.controller;

import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.model.PutObjectRequest;
import com.amazonaws.services.s3.model.S3Object;
import com.amazonaws.util.IOUtils;
import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class FileUploadController {

    @Autowired
    private AmazonS3 amazonS3;

    @Value("${cloud.aws.s3.bucket}")
    private String bucketName;

    @PostMapping("/upload-profile-pic")
    public ResponseEntity<String> uploadProfilePic(@RequestParam("username") String username, @RequestParam("profilePic") MultipartFile profilePic) {
        String fileName = username + "-profilepic.png";

        try {
            amazonS3.putObject(new PutObjectRequest(bucketName, fileName, profilePic.getInputStream(), null));
            return ResponseEntity.ok("Profile picture uploaded successfully");
        } catch (IOException e) {
            return ResponseEntity.status(500).body("Failed to upload profile picture");
        }
    }

    @GetMapping("/get-profile-pic/{username}/{opponentUsername}")
    public ResponseEntity<Map<String, String>> getProfilePic(@PathVariable String username, @PathVariable String opponentUsername) {
        Map<String, String> response = new HashMap<>();

        try {
            S3Object player1PicObject = amazonS3.getObject(bucketName, username + "-profilepic.png");
            byte[] player1PicBytes = IOUtils.toByteArray(player1PicObject.getObjectContent());

            S3Object player2PicObject = amazonS3.getObject(bucketName, opponentUsername + "-profilepic.png");
            byte[] player2PicBytes = IOUtils.toByteArray(player2PicObject.getObjectContent());

            String player1PicBase64 = Base64.getEncoder().encodeToString(player1PicBytes);
            String player2PicBase64 = Base64.getEncoder().encodeToString(player2PicBytes);

            response.put("player1Pic", player1PicBase64);
            response.put("player2Pic", player2PicBase64);
            response.put("player1Name", username);
            response.put("player2Name", opponentUsername);
        } catch (IOException e) {
            return ResponseEntity.status(500).body(null);
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        return ResponseEntity.ok().headers(headers).body(response);
    }
}
