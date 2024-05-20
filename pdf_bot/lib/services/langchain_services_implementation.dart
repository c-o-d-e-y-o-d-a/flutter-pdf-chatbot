import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain/src/documents/models/models.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_pinecone/langchain_pinecone.dart';
import 'package:pdf_bot/services/langchain_service.dart';
import 'package:pinecone/pinecone.dart';





class LangchainServiceImpl implements LangChainService {

  final PineconeClient client;
  final Pinecone langchainPinecone;
  final OpenAIEmbeddings embeddings;
  final OpenAI openAI;

  LangchainServiceImpl({
    required this.client,
    required this.langchainPinecone,
    required this.embeddings,
    required this.openAI,

  });

  @override
  Future<void> createPineConeIndex(String indexName, int vectorDimension) async {
    print("Checking $indexName");
    final indexes = await client.listIndexes();
    if(!indexes.contains(indexName)){
      print("Creating $indexName ...");
      await client.createIndex(
        environment: dotenv.env['PINE_ENVIRONMENT']!,
        request: CreateIndexRequest(
        name: indexName,
        dimension: vectorDimension,
        metric: SearchMetric.cosine,

        ));
        print("Creating index..... please wait for it to finish initializing.");
    }

    else{
      print("$indexName already exists");
    }

  }



  @override
  Future<String> queryPineConeVectorStore(String indexName, String query) async {

    

    final queryEmbeddings = await embeddings.embedQuery(query);
    final result = await langchainPinecone.similaritySearchByVector(embedding: queryEmbeddings);

    if(result.isNotEmpty){
      final concatPageContent = result.map((e) {
        //check if the metadata has a page context key or not
        if(e.metadata.containsKey('pageContent')){
          return e.metadata['pageContent'];

        }
        else{
          return '';
        }
      }).join(' ');


      final docChain = StuffDocumentsQAChain( llm: openAI);

      final response = await docChain.call({
        'input_document':[Document(pageContent: concatPageContent)],
        'question' : query,
      });

      print(result);

      return response['output'];
    }

    else{
      return "No results found";
    }
    
    
  }





  @override

  Future<void> updatePineConeIndex(
      String indexname, List<Document> docs) async {
    print("Retreiving Pinecone index...");
    final index = await client.describeIndex(
        indexName: indexname, environment: dotenv.env['PINE_ENVIRONMENT']!);
    print('!Pinecone index retrieved: ${index.name}');


    for(final doc in docs){
      print('Processing document: ${doc.metadata['source']}');
      final text = doc.pageContent;

      const textSplitter = RecursiveCharacterTextSplitter(chunkSize: 1000);

      final chunks = textSplitter.createDocuments([text]);

      print('Text split into ${chunks.length} chunks');

      print(
        'Calling OpenAI\'s Embedding endpoint documents with ${chunks.length} text chunks...'
      );

      final ChunksMap = chunks.map(
        (e) => Document(
          id: e.id,
          pageContent: e.pageContent.replaceAll(RegExp('/\n/g'), " " ),
          metadata: doc.metadata,
           )
           ).toList();

        final embeddingArrays = await embeddings.embedDocuments(ChunksMap);

        print('Finished embedding documents');
        print(
          'Creating ${chunks.length} vectors array with id, values and metadata...'
        );
    }
  }


}