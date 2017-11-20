component extends="testbox.system.BaseSpec" {

	public void function run() {
		describe( "runTask()", function(){
			it( "should call the handler defined for the task, passing additional args set, a special logger and special progress object for the task", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var event   = "some.handler.action";
				var args    = { test=CreateUUId(), fubar=123 };
				var taskDef = QueryNew( 'event,event_args,status', 'varchar,varchar,varchar', [ [ event, SerializeJson( args ), "pending" ] ] );

				_mockGetTask( taskId, taskDef );
				mockColdbox.$( "runEvent" );
				var mockProgress = _mockProgress( service, taskId );
				var mockLogger   = _mockLogger( service, taskId );

				service.$( "completeTask" );
				service.$( "failTask" );
				mockTaskDao.$( "updateData" );

				expect( service.runTask( taskId ) ).toBe( true );

				var log = mockColdbox.$callLog().runEvent;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  event          = event
					, eventArguments = { args=args, logger=mockLogger, progress=mockProgress }
					, private        = true
					, prepostExempt  = true
				} );
			} );

			it( "should mark the task as running during the process", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var event   = "some.handler.action";
				var args    = { test=CreateUUId(), fubar=123 };
				var taskDef = QueryNew( 'event,event_args,status', 'varchar,varchar,varchar', [ [ event, SerializeJson( args ), "pending" ] ] );

				_mockGetTask( taskId, taskDef );
				mockColdbox.$( "runEvent" );
				var mockProgress = _mockProgress( service, taskId );
				var mockLogger   = _mockLogger( service, taskId );

				service.$( "completeTask" );
				service.$( "failTask" );
				mockTaskDao.$( "updateData" );

				service.runTask( taskId );

				log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( { id=taskId, data={ status="running" } } );
			} );

			it( "should mark the task as complete when finished successfully", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var event   = "some.handler.action";
				var args    = { test=CreateUUId(), fubar=123 };
				var taskDef = QueryNew( 'event,event_args,status', 'varchar,varchar,varchar', [ [ event, SerializeJson( args ), "pending" ] ] );

				_mockGetTask( taskId, taskDef );
				mockColdbox.$( "runEvent" );
				var mockProgress = _mockProgress( service, taskId );
				var mockLogger   = _mockLogger( service, taskId );

				service.$( "completeTask" );
				service.$( "failTask" );
				mockTaskDao.$( "updateData" );

				service.runTask( taskId );

				log = service.$callLog().completeTask;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( { taskId=taskId } );
			} );

			it( "should return false, fail the task and log error when an error is thrown during execution of the handler action", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var event   = "some.handler.action";
				var args    = { test=CreateUUId(), fubar=123 };
				var taskDef = QueryNew( 'event,event_args,status', 'varchar,varchar,varchar', [ [ event, SerializeJson( args ), "pending" ] ] );

				_mockGetTask( taskId, taskDef );
				var mockProgress = _mockProgress( service, taskId );
				var mockLogger   = _mockLogger( service, taskId );

				mockColdbox.$( "runEvent" ).$throws( type="SomeError", message="boo :(" );
				service.$( "$raiseError" );
				service.$( "completeTask" );
				service.$( "failTask" );
				mockTaskDao.$( "updateData" );

				expect( service.runTask( taskId ) ).toBe( false );

				var log = service.$callLog().$raiseError;
				expect( log.len() ).toBe( 1 );
				expect( log[1].error.type    ?: "" ).toBe( "SomeError" );
				expect( log[1].error.message ?: "" ).toBe( "boo :(" );

				var log = service.$callLog().failTask;
				expect( log.len() ).toBe( 1 );
				expect( log[1].taskId ).toBe( taskId );
				expect( log[1].error.type    ?: "" ).toBe( "SomeError" );
				expect( log[1].error.message ?: "" ).toBe( "boo :(" );
			} );

			it( "should silenty raise an error and return false when the task is already running", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var event   = "some.handler.action";
				var args    = { test=CreateUUId(), fubar=123 };
				var taskDef = QueryNew( 'event,event_args,status', 'varchar,varchar,varchar', [ [ event, SerializeJson( args ), "running" ] ] );

				_mockGetTask( taskId, taskDef );
				var mockProgress = _mockProgress( service, taskId );
				var mockLogger   = _mockLogger( service, taskId );

				mockColdbox.$( "runEvent" );
				service.$( "$raiseError" );
				service.$( "completeTask" );
				service.$( "failTask" );
				mockTaskDao.$( "updateData" );

				expect( service.runTask( taskId ) ).toBe( false );
				expect( mockColdbox.$callLog().runEvent.len() ).toBe( 0 );

				var log = service.$callLog().$raiseError;
				expect( log.len() ).toBe( 1 );
				expect( log[1].error.type    ?: "" ).toBe( "AdHoTaskManagerService.task.already.running" );
				expect( log[1].error.message ?: "" ).toBe( "Task not run. The task with ID, [#taskId#], is already running." );
			} );
		} );

		describe( "createTask()", function(){
			it( "should insert a new record into the adhoc task table and return the ID", function(){
				var service = _getService();
				var owner   = CreateUUId();
				var event   = "some.event";
				var args    = { test=CreateUUId(), foobar=[ 1, 2, CreateUUId() ] };
				var taskId  = CreateUUId();

				mockTaskDao.$( "insertData" ).$args( {
					  event               = event
					, event_args          = SerializeJson( args )
					, admin_owner         = owner
					, web_owner           = ""
					, discard_on_complete = false
					, retry_interval      = "[]"
				} ).$results( taskId );

				expect( service.createTask(
					  adminOwner = owner
					, event      = event
					, args       = args
				) ).toBe( taskId );
			} );

			it( "should run the newly created task in a new thread if 'runNow' is passed and is 'true'", function(){
				var service = _getService();
				var owner   = CreateUUId();
				var event   = "some.event";
				var args    = { test=CreateUUId(), foobar=[ 1, 2, CreateUUId() ] };
				var taskId  = CreateUUId();

				mockTaskDao.$( "insertData" ).$args( {
					  event               = event
					, event_args          = SerializeJson( args )
					, admin_owner         = ""
					, web_owner           = owner
					, discard_on_complete = true
					, retry_interval      = "[]"
				} ).$results( taskId );
				service.$( "runTaskInThread" );

				service.createTask(
					  webOwner          = owner
					, event             = event
					, args              = args
					, runNow            = true
					, discardOnComplete = true
				);

				var log = service.$callLog().runTaskInThread;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( { taskId=taskId } );
			} );
		} );

		describe( "completeTask()", function(){
			it( "should update status of db record", function(){
				var service = _getService();
				var taskId = CreateUUId();

				mockTaskDao.$( "updateData", 1 );

				service.$( "getTask" ).$args( taskId ).$results( QueryNew( 'discard_on_complete', 'boolean', [[ false ]] ) );
				service.completeTask( taskId );

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  id   = taskId
					, data = { status="succeeded" }
				} );
			} );

			it( "should discard the task if set to discard on complete", function(){
				var service = _getService();
				var taskId = CreateUUId();

				service.$( "getTask" ).$args( taskId ).$results( QueryNew( 'discard_on_complete', 'boolean', [[ true ]] ) );
				service.$( "discardTask", true );
				mockTaskDao.$( "updateData", 1 );

				service.completeTask( taskId );

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 0 );

				log = service.$callLog().discardTask;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( { taskId=taskId } );
			} );
		} );

		describe( "failTask()", function(){
			it( "should update status of db record to failed when no retry attempts defined", function(){
				var service     = _getService();
				var taskId      = CreateUUId();
				var error       = { type="test.error", message="Something went wrong" };
				var nextAttempt = { totalAttempts=1, nextAttemptDate="" };

				mockTaskDao.$( "updateData", 1 );
				service.$( "getNextAttemptInfo" ).$args( taskId ).$results( nextAttempt );

				service.failTask( taskId, error );

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  id   = taskId
					, data = { status="failed", last_error=SerializeJson( error ), attempt_count=nextAttempt.totalAttempts }
				} );
			} );

			it( "should requeue task when another attempt is due", function(){
				var service     = _getService();
				var taskId      = CreateUUId();
				var error       = { type="test.error", message="Something went wrong" };
				var nextAttempt = { totalAttempts=3, nextAttemptDate=DateAdd( "n", 40, Now() ) };

				mockTaskDao.$( "updateData", 1 );
				service.$( "getNextAttemptInfo" ).$args( taskId ).$results( nextAttempt );
				service.$( "requeueTask" );

				service.failTask( taskId, error );

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 0 );

				log = service.$callLog().requeueTask;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  taskId          = taskId
					, error           = error
					, attemptCount    = nextAttempt.totalAttempts
					, nextAttemptDate = nextAttempt.nextAttemptDate
				} );
			} );
		} );

		describe( "setProgress()", function(){
			it( "should set the progress percentage against the DB record", function(){
				var service = _getService();
				var taskId = CreateUUId();
				var progress = 84;

				mockTaskDao.$( "updateData", 1 );

				service.setProgress( taskId, progress );

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  id   = taskId
					, data = { progress_percentage=progress }
				} );
			} );
		} );

		describe( "setResult()", function(){
			it( "should set the task result against the DB record", function(){
				var service = _getService();
				var taskId = CreateUUId();
				var result = { complex=true, random=[ CreateUUId() ] };

				mockTaskDao.$( "updateData", 1 );

				service.setResult( taskId, result );

				var log = mockTaskDao.$callLog().updateData;
				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( {
					  id   = taskId
					, data = { result=SerializeJson( result ) }
				} );
			} );
		} );

		describe( "getProgress()", function(){
			it( "should return a struct with task ID, status, progress and result from the DB record", function(){
				var service  = _getService();
				var taskId   = CreateUUId();
				var dbResult = QueryNew( 'id,status,progress_percentage,result', 'varchar,varchar,varchar,varchar', [[ taskId, "running", 45, "{ test:'this' }" ]] );
				var expected = {
					  id       = dbResult.id
					, status   = dbResult.status
					, progress = dbResult.progress_percentage
					, result   = DeserializeJson( dbResult.result )
				};

				service.$( "getTask" ).$args( taskId ).$results( dbResult );

				expect( service.getProgress( taskId ) ).toBe( expected );
			} );

			it( "should return an empty struct when the task does not exist", function(){
				var service  = _getService();
				var taskId   = CreateUUId();
				var dbResult = QueryNew( 'id,status,progress_percentage,result' );

				service.$( "getTask" ).$args( taskId ).$results( dbResult );

				expect( service.getProgress( taskId ) ).toBe( {} );
			} );
		} );

		describe( "discardTask()", function(){
			it( "should delete the task from the database", function(){
				var service  = _getService();
				var taskId   = CreateUUId();

				mockTaskDao.$( "deleteData", 1 );

				expect( service.discardTask( taskId ) ).toBe( true );

				var log = mockTaskDao.$callLog().deleteData;

				expect( log.len() ).toBe( 1 );
				expect( log[1] ).toBe( { id=taskId } );
			} );
		} );

		describe( "getNextAttemptInfo()", function(){
			it( "should should return a struct with totalAttempts set to previous attempts+1 and an empty string for next date, when task has no retry attempts configured", function(){
				var service = _getService();
				var taskId  = CreateUUId();
				var task    = QueryNew( "retry_interval,attempt_count", "varchar,int", [ [ "[]", 0 ] ] );

				service.$( "getTask" ).$args( taskId ).$results( task );

				expect( service.getNextAttemptInfo( taskId ) ).toBe( { totalAttempts=1, nextAttemptDate="" } );
			} );

			it( "should return an empty struct when the task is all out of retries", function(){
				var service       = _getService();
				var taskId        = CreateUUId();
				var retryInterval = [ { tries=3,interval=5 }, { tries=2, interval=30 } ];
				var task          = QueryNew( "retry_interval,attempt_count", "varchar,int", [ [ SerializeJson( retryInterval ), 4 ] ] );

				service.$( "getTask" ).$args( taskId ).$results( task );

				expect( service.getNextAttemptInfo( taskId ) ).toBe( { totalAttempts=5, nextAttemptDate="" } );
			} );

			it( "should return a struct with 'nextAttemptDate' calculated from current date + next retry interval + 'totalAttempts' from database attempt count (plus one)", function(){
				var service       = _getService();
				var taskId        = CreateUUId();
				var retryInterval = [ { tries=3,interval=5 }, { tries=2, interval=30 } ];
				var task          = QueryNew( "retry_interval,attempt_count", "varchar,int", [ [ SerializeJson( retryInterval ), 3 ] ] );

				service.$( "getTask" ).$args( taskId ).$results( task );

				expect( service.getNextAttemptInfo( taskId ) ).toBe( {
					  totalAttempts   = 4
					, nextAttemptDate = DateTimeFormat( DateAdd( "n", 30, Now() ), "yyyy-mm-dd HH:nn" )
				} );
			} );
		} );
	}


// private helpers
	private any function _getService() {
		var service = new preside.system.services.taskmanager.AdHocTaskManagerService();

		service = CreateMock( object=service );

		mockTaskDao = CreateStub();
		mockColdbox = CreateStub();

		service.$( "$getPresideObject" ).$args( "taskmanager_adhoc_task" ).$results( mockTaskDao );
		service.$( "$getColdbox", mockColdbox );

		return service;
	}

	private void function _mockGetTask( required string taskId, required query result ) {
		mockTaskDao.$( "selectData" ).$args( id=arguments.taskId ).$results( arguments.result );
	}

	private any function _mockProgress( required any service, required string taskId ) {
		var dummyObj    = CreateStub();
		    dummyObj.id = CreateUUId();

		service.$( "_getTaskProgressReporter" ).$args( arguments.taskId ).$results( dummyObj );

		return dummyObj;
	}
	private any function _mockLogger( required any service, required string taskId ) {
		var dummyObj    = CreateStub();
		    dummyObj.id = CreateUUId();

		service.$( "_getTaskLogger" ).$args( arguments.taskId ).$results( dummyObj );

		return dummyObj;
	}
}