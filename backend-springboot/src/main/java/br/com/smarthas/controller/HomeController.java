package br.com.smarthas.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

    @GetMapping("/")
    public String index(Model model) {
        model.addAttribute("apiName", "Smart HAS API");
        model.addAttribute("status", "online");
        model.addAttribute("version", "1.0.0");
        return "index";
    }
}
