package main

import (
	"fmt"
	"os"

	"github.com/labstack/echo/v4"
	"product/spec"
	"product/api"
)

func main() {
	productStore := api.NewProductStore()
	e := echo.New()
	spec.RegisterHandlers(e, productStore)

	port, ok := os.LookupEnv("PORT")
	if !ok {
		port = "8081"
	}

	err := e.Start(":" + port)
	if err != nil {
		fmt.Printf("Error starting server om port '%s': %s.", port, err)
		return
	}
}
