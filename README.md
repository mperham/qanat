QANAT
======

Concurrent message queue processing for Ruby.

Qanat is one of the few words recognized by Scrabble that begin with Q and don't require a U following.

Context
---------

The Ruby 1.8 and 1.9 VM implementations do not scale well.  Ruby 1.8 threads can't execute more than one at a time and on more than one core.  Many Ruby extensions are not thread-safe and Ruby itself places a GIL around many operations such that multiple Ruby threads can't execute concurrently.  JRuby is the only exception to this limitation currently but threaded code itself has issues - thread-safe code is notoriously difficult to write, debug and test. 

Many people use S3, SQS and SimpleDB to store data.  Those services scale very well to huge volumes of data but don't have incredible response times so when you write code which grabs a message from a queue, performs a SimpleDB lookup, makes a change and stores some other data to S3, that entire process might take 2 seconds, where 0.1 sec is actually spent performing calculations with the CPU and the other 1.9 seconds is spent blocked, doing nothing and waiting for the various Amazon web services to respond.

Qanat is a queue processor daemon which uses an event-driven architecture to work around these issues.  It works well for processing messages which spend a lot of time performing I/O, e.g. messages which require calling 3rd party web services, scraping other web sites, making long database queries, etc.


Design
-------

Qanat will process many messages concurrently, using EventMachine to manage the overall processing.  Ruby 1.9 is required.

Qanat supports any MQ system by providing a driver for each type of system.  See `lib/drivers`.  Drivers for Beanstalk and SQS are provided out of the box.

Qanat provides basic implementations of SQS, SimpleDB and S3 event-based clients.  These clients can be used in your own message processing code.

Install
---------

    gem install qanat


Configuration
----------------

You will need to configure your MQ server and the queues to process.  See the simple DSL example in `config/pre-daemonize/qanat.rb`.

    Qanat.setup do
      # Example: Local beanstalk MQ server
      server :beanstalk do
        host 'localhost'
        port 11300
      end

      # Example: Amazon SQS
      server :sqs do
        access_key '25NFSD73ACZA0222PMR2'
        secret_key 'FHGkQP3f3d1dDLk4ZbDh5ph2S9JkiSQ2rxyxJZyg'
      end

      # Now define the queues to process
      queue 'image_crawling' do
        worker_count 10
        processor ImageCrawler
      end
   
      queue 'page_indexing' do |q|
        worker_count 20
        processor PageIndexer
      end
    end

Qanat will spin up 30 Fibers, each Fiber will have its own instance of the processor class, which 
must have a `process(msg)` method.


Author
--------

Mike Perham, @mperham, http://mikeperham.com, mperham AT gmail.com