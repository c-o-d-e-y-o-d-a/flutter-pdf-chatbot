import 'package:langchain/src/documents/models/models.dart';
import 'package:pdf_bot/services/langchain_service.dart';
import 'package:pinecone/pinecone.dart';





class LangchainServiceImpl implements LangChainService {

  final PineconeClient client;
  final Pinecone langchainPinecone;
  final OpenAiEmbeddings embeddings;
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
      await client.createIndex(request: CreateIndexRequest(
        name: indexName,
        dimension: vectorDimension,
        metric: SearchMetric.cosine,

        ));
    }

  }

  @override
  Future<String> queryPineConeVectorStore(String indexName, String query) {
    // TODO: implement queryPineConeVectorStore
    throw UnimplementedError();
  }

  @override
  Future<void> updatePineConeIndex(String indexname, List<Document> docs) {
    // TODO: implement updatePineConeIndex
    throw UnimplementedError();
  }


}