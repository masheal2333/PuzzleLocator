from app.api.users import routes as users_routes
from app.api.puzzles import routes as puzzles_routes
from app.api.algorithms import routes as algorithms_routes

router = users_routes.router
router.include_router(puzzles_routes.router)
router.include_router(algorithms_routes.router)
