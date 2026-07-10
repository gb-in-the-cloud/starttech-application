package routes

import (
	"github.com/gin-gonic/gin"

	"github.com/Innocent9712/much-to-do/Server/MuchToDo/internal/handlers"
)

func RegisterRoutes(
	router *gin.Engine,
	userHandler *handlers.UserHandler,
	todoHandler *handlers.TodoHandler,
	healthHandler *handlers.HealthHandler,
	authMiddleware gin.HandlerFunc,
) {
	router.GET("/health", healthHandler.Health)

	auth := router.Group("/auth")
	{
		auth.POST("/register", userHandler.Register)
		auth.POST("/login", userHandler.Login)
	}

	api := router.Group("/api", authMiddleware)
	{
		api.GET("/profile", userHandler.GetProfile)
		api.DELETE("/account", userHandler.DeleteAccount)

		todos := api.Group("/todos")
		{
			todos.GET("", todoHandler.GetTodos)
			todos.POST("", todoHandler.CreateTodo)
			todos.GET("/:id", todoHandler.GetTodo)
			todos.PUT("/:id", todoHandler.UpdateTodo)
			todos.DELETE("/:id", todoHandler.DeleteTodo)
		}
	}
}
