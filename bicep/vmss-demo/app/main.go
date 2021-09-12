package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gofiber/fiber/v2"
)

func main() {
    // Create new Fiber instance
    app := fiber.New()

	host, err := os.Hostname()
	if err !=nil {
		fmt.Errorf(err.Error())
	}

	str := fmt.Sprintf("Hello from hostname: %s \n", host)

    // Make path with some content
    app.Get("/", func(c *fiber.Ctx) error {
        // Return a string with a dummy text
        return c.SendString(str)
    })

    // Start server on http://localhost:3000 or error
    log.Fatal(app.Listen(":3000"))
}