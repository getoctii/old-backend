local lapis = require 'lapis'
local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to
local json_params = require 'lapis.application'.json_params

local app = lapis.Application()
app.__base = app
app.name = "products."
app.path = "/products"

app:match('product', '/:id', guard(json_params(respond_to(require 'routes.products.product' ))))
app:match('resources', '/:id/resources', guard(json_params(respond_to(require 'routes.products.resources' ))))
app:match('resource', '/:id/resources/:resource_id', guard(json_params(respond_to(require 'routes.products.resource' ))))
app:match('resource_payload', '/:id/resources/:resource_id/payload', guard(json_params(respond_to(require 'routes.products.resource_payload' ))))
app:match('versions', '/:id/versions', guard(json_params(respond_to(require 'routes.products.versions' ))))
app:match('version', '/:id/versions/:version_id', guard(json_params(respond_to(require 'routes.products.version' ))))
app:match('purchase', '/:id/purchase', guard(json_params(respond_to(require 'routes.products.purchase' ))))
app:match('search', '/search', guard(json_params(respond_to(require 'routes.products.search' ))))
app:match('version_payload', '/:id/versions/:version_id/payload', guard(json_params(respond_to(require 'routes.products.version_payload' ))))
app:match('featured', '/featured', guard(json_params(respond_to(require 'routes.products.featured' ))))

return app