package main

import (
	"fmt"
	"os"

	"github.com/labstack/echo/v4"
	"order/spec"
	"order/api"
)

func main() {
	orderStore := api.NewOrderStore()
	e := echo.New()
	spec.RegisterHandlers(e, orderStore)

	port, ok := os.LookupEnv("PORT")
	if !ok {
		port = "8080"
	}

	err := e.Start(":" + port)
	if err != nil {
		fmt.Printf("Error starting server om port '%s': %s.", port, err)
		return
	}
}
