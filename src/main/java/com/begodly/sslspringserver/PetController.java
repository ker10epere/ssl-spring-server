package com.begodly.sslspringserver;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequestMapping("/pet")
@RestController
public class PetController {
    @GetMapping
    public String pet() {
        return "Kira";
    }
}
