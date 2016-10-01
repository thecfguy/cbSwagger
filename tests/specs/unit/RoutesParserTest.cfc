/*******************************************************************************
* Routes Parser Test
*******************************************************************************/
component extends="coldbox.system.testing.BaseTestCase" appMapping="/" accessors=true{
	property name="cbSwaggerSettings" inject="coldbox:setting:cbSwagger";
	property name="wirebox" inject="wirebox";
	property name="controller" inject="coldbox";
	
	this.loadColdbox=true;

	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		super.beforeAll();
		
		// do your own stuff here
		expect( application ).toHaveKey( "wirebox", "Wirebox is required to run this test" );
		application.wirebox.autowire( this );
		expect( isNull( Controller ) ).toBeFalse( "Autowiring failed.  Could not continue" );

		VARIABLES.testHandlerMetadata = getMetaData( createObject( "component", "handlers.api.v1.Users" ) );
	}

	function afterAll(){
		// do your own stuff here
		super.afterAll();

	}

	/*********************************** BDD SUITES ***********************************/
	
	function run(){

		describe( "Tests core RouteParser Methods", function(){

			it("Tests the creation document generated by createDocFromRoutes", function(){
				var RoutesParser = Wirebox.getInstance( "RoutesParser@cbSwagger" );
				expect( RoutesParser ).toBeComponent();
				var APIDoc = RoutesParser.createDocFromRoutes();
				expect( APIDoc ).toBeComponent();
				var NormalizedDoc = APIDoc.getNormalizedDocument();
				expect( NormalizedDoc ).toBeStruct();
				expect(	NormalizedDoc ).toHaveKey( "swagger" );

				expect( isJSON( APIDoc.asJSON() ) ).toBeTrue();

				VARIABLES.APIDoc = APIDoc;
			});

			it( "Tests the API Document against the routing configuration", function(){
				var SwaggerUtil = Wirebox.getInstance( "OpenAPIUtil@SwaggerSDK" );
				expect( VARIABLES ).toHaveKey( "APIDoc", "No APIDoc was found to test.  Could not continue." );
				var NormDoc = VARIABLES.APIDoc.getNormalizedDocument();
				expect( NormDoc ).toHaveKey( "paths" );
				var APIPaths = NormDoc[ "paths" ];
				//pull our routing configuration
				var apiPrefixes = cbSwaggerSettings.routes;
				expect( apiPrefixes ).toBeArray();
				var CBRoutes = getController().getInterceptorService().getInterceptor("SES").getRoutes();
				expect( CBRoutes ).toBeArray();

				//Tests that all of our configured paths exist
				for( var routePrefix in apiPrefixes ){				
					for( var route in cbRoutes ){
						if( left( route.pattern, len( routePrefix ) ) == routePrefix ){
							var translatedPath = SwaggerUtil.translatePath( route.pattern );
							if( !len( route.moduleRouting ) ){
								expect( NormDoc[ "paths" ] ).toHaveKey( translatedPath );
							}
						}
					}
				}

			});

			it( "Tests the API Document for module introspection", function(){
				var SwaggerUtil = Wirebox.getInstance( "OpenAPIUtil@SwaggerSDK" );
				expect( VARIABLES ).toHaveKey( "APIDoc", "No APIDoc was found to test.  Could not continue." );
				var NormDoc = VARIABLES.APIDoc.getNormalizedDocument();
				expect( NormDoc ).toHaveKey( "paths" );
				var APIPaths = NormDoc[ "paths" ];
				//pull our routing configuration
				var apiPrefixes = cbSwaggerSettings.routes;
				expect( apiPrefixes ).toBeArray();
				var TLRoutes = getController().getInterceptorService().getInterceptor("SES").getRoutes();
				expect( TLRoutes ).toBeArray();

				for( var TLRoute in TLRoutes ){
					if( len( TLRoute.moduleRouting ) ){
						var CBRoutes = getController().getInterceptorService().getInterceptor("SES").getModuleRoutes( TLRoute.moduleRouting );
						//Tests that all of our configured paths exist
						for( var routePrefix in apiPrefixes ){
							//recurse into the module routes
							for( var route in CBRoutes ){
								if( left( route.pattern, len( routePrefix ) ) == routePrefix ){
									var translatedPath = SwaggerUtil.translatePath( route.pattern );
									expect( NormDoc[ "paths" ] ).toHaveKey( translatedPath );
								}
							}
						}	
					}
				}

			});
		
		});

	}

}
