Nice, this is the fun part 😄
I’ll give you clean C# boilerplate for an ASP.NET Core microservice:

No real implementation, just interfaces, DTOs, enums, controller skeletons.

Designed to handle Invoice now, and Payment / Deposit later without redesign.



---

1. Boilerplate microservice code (no implementation)

// ===============================
// Contracts / DTOs / Enums
// ===============================
namespace DocumentIntelligence.Contracts
{
    public enum DocumentType
    {
        Unknown = 0,
        Invoice = 1,
        Payment = 2,
        Deposit = 3
    }

    public enum ExtractionStatus
    {
        Pending = 0,
        InProgress = 1,
        Success = 2,
        Failed = 3,
        Skipped = 4
    }

    // Request coming from legacy app / upload flow to start extraction
    public sealed class ExtractionRequestDto
    {
        public Guid DocumentId { get; set; }
        public string BlobPath { get; set; } = string.Empty;
        public DocumentType DocumentType { get; set; }

        // Optional, for future multi-tenant / client logic
        public string? TenantId { get; set; }
    }

    // Response when starting extraction (async pattern)
    public sealed class ExtractionAcceptedResponseDto
    {
        public Guid DocumentId { get; set; }
        public ExtractionStatus Status { get; set; } = ExtractionStatus.Pending;
        public string? Message { get; set; }
    }

    // Status / result DTO that legacy can query (if needed)
    public sealed class ExtractionStatusDto
    {
        public Guid DocumentId { get; set; }
        public DocumentType DocumentType { get; set; }
        public ExtractionStatus Status { get; set; }
        public string? Provider { get; set; }       // Azure / AWS / Custom
        public string? ModelVersion { get; set; }
        public decimal? Confidence { get; set; }    // 0.0 – 1.0

        // Normalized JSON that will also be stored in DB
        public string? NormalizedJson { get; set; }

        public DateTimeOffset CreatedOnUtc { get; set; }
        public DateTimeOffset? CompletedOnUtc { get; set; }
    }
}

// ===============================
// Domain Models (for internal use)
// ===============================
namespace DocumentIntelligence.Domain
{
    using DocumentIntelligence.Contracts;

    // Internal request model used inside the microservice
    public sealed class DocumentExtractionRequest
    {
        public Guid DocumentId { get; set; }
        public string BlobPath { get; set; } = string.Empty;
        public DocumentType DocumentType { get; set; }
        public string? TenantId { get; set; }
    }

    // Result of a single extraction operation
    public sealed class DocumentExtractionResult
    {
        public Guid DocumentId { get; set; }
        public DocumentType DocumentType { get; set; }
        public ExtractionStatus Status { get; set; }
        public string? NormalizedJson { get; set; }
        public string? Provider { get; set; }
        public string? ModelVersion { get; set; }
        public decimal? Confidence { get; set; }
        public DateTimeOffset CreatedOnUtc { get; set; }
        public DateTimeOffset? CompletedOnUtc { get; set; }
        public string? ErrorCode { get; set; }
        public string? ErrorMessage { get; set; }
    }
}

// ===============================
// Provider abstraction (Azure / AWS / Custom)
// ===============================
namespace DocumentIntelligence.Providers
{
    using DocumentIntelligence.Domain;

    /// <summary>
    /// High-level abstraction for "something that can extract structured data from a document."
    /// We can have multiple implementations:
    /// - AzureDocumentExtractionProvider
    /// - AwsDocumentExtractionProvider
    /// - CustomDocumentExtractionProvider
    /// </summary>
    public interface IDocumentExtractionProvider
    {
        Task<DocumentExtractionResult> ExtractAsync(
            DocumentExtractionRequest request,
            CancellationToken cancellationToken = default);
    }
}

// ===============================
// Orchestrator abstraction
// ===============================
namespace DocumentIntelligence.Application
{
    using DocumentIntelligence.Contracts;

    /// <summary>
    /// Orchestrates the extraction process:
    /// - Accepts requests from the API
    /// - Optionally enqueues work for async processing
    /// - Persists results to the database
    /// - Exposes status/result
    /// </summary>
    public interface IExtractionOrchestrator
    {
        Task<ExtractionAcceptedResponseDto> StartExtractionAsync(
            ExtractionRequestDto request,
            CancellationToken cancellationToken = default);

        Task<ExtractionStatusDto?> GetStatusAsync(
            Guid documentId,
            CancellationToken cancellationToken = default);
    }
}

// ===============================
// Persistence abstraction
// ===============================
namespace DocumentIntelligence.Persistence
{
    using DocumentIntelligence.Domain;
    using DocumentIntelligence.Contracts;

    /// <summary>
    /// Responsible for reading/writing extraction records (e.g. DocumentExtraction table).
    /// </summary>
    public interface IExtractionRepository
    {
        Task SaveResultAsync(
            DocumentExtractionResult result,
            CancellationToken cancellationToken = default);

        Task<DocumentExtractionResult?> GetByDocumentIdAsync(
            Guid documentId,
            CancellationToken cancellationToken = default);

        Task UpdateStatusAsync(
            Guid documentId,
            ExtractionStatus status,
            string? errorCode,
            string? errorMessage,
            CancellationToken cancellationToken = default);
    }
}

// ===============================
// API Controller (skeleton)
// ===============================
using DocumentIntelligence.Application;
using DocumentIntelligence.Contracts;
using Microsoft.AspNetCore.Mvc;

namespace DocumentIntelligence.Api.Controllers
{
    [ApiController]
    [Route("api/extraction")]
    public class ExtractionController : ControllerBase
    {
        private readonly IExtractionOrchestrator _orchestrator;

        public ExtractionController(IExtractionOrchestrator orchestrator)
        {
            _orchestrator = orchestrator;
        }

        /// <summary>
        /// Trigger extraction for a document (Invoice now, Payment/Deposit later).
        /// Expected to be called by the upload flow or legacy app.
        /// </summary>
        [HttpPost]
        public async Task<ActionResult<ExtractionAcceptedResponseDto>> StartExtractionAsync(
            [FromBody] ExtractionRequestDto request,
            CancellationToken cancellationToken)
        {
            // TODO: validation
            // TODO: logging
            var response = await _orchestrator.StartExtractionAsync(request, cancellationToken);
            return AcceptedAtAction(
                nameof(GetStatusAsync),
                new { documentId = response.DocumentId },
                response);
        }

        /// <summary>
        /// Optional: Check current status/result of extraction for a document.
        /// Legacy app might not need this, but it's useful for diagnostics.
        /// </summary>
        [HttpGet("{documentId:guid}")]
        public async Task<ActionResult<ExtractionStatusDto>> GetStatusAsync(
            [FromRoute] Guid documentId,
            CancellationToken cancellationToken)
        {
            var status = await _orchestrator.GetStatusAsync(documentId, cancellationToken);
            if (status is null)
            {
                return NotFound();
            }

            return Ok(status);
        }
    }
}

// ===============================
// Program.cs (minimal hosting skeleton)
// ===============================
using DocumentIntelligence.Application;
using DocumentIntelligence.Persistence;
using DocumentIntelligence.Providers;

var builder = WebApplication.CreateBuilder(args);

// Controllers / API
builder.Services.AddControllers();

// Dependency injection registrations
// Concrete implementations intentionally omitted.
builder.Services.AddScoped<IExtractionOrchestrator, /* ExtractionOrchestrator */    DummyExtractionOrchestrator>();
builder.Services.AddScoped<IExtractionRepository,  /* ExtractionRepository */       DummyExtractionRepository>();
builder.Services.AddScoped<IDocumentExtractionProvider, /* Azure/AWS/Custom */     DummyDocumentExtractionProvider>();

var app = builder.Build();

app.MapControllers();

app.Run();

// ===============================
// Dummy classes just to make the project compile,
// you will replace with real implementations.
// ===============================
public class DummyExtractionOrchestrator : IExtractionOrchestrator
{
    public Task<ExtractionAcceptedResponseDto> StartExtractionAsync(ExtractionRequestDto request, CancellationToken cancellationToken = default)
        => throw new NotImplementedException();

    public Task<ExtractionStatusDto?> GetStatusAsync(Guid documentId, CancellationToken cancellationToken = default)
        => throw new NotImplementedException();
}

public class DummyExtractionRepository : IExtractionRepository
{
    public Task SaveResultAsync(DocumentIntelligence.Domain.DocumentExtractionResult result, CancellationToken cancellationToken = default)
        => throw new NotImplementedException();

    public Task<DocumentIntelligence.Domain.DocumentExtractionResult?> GetByDocumentIdAsync(Guid documentId, CancellationToken cancellationToken = default)
        => throw new NotImplementedException();

    public Task UpdateStatusAsync(Guid documentId, ExtractionStatus status, string? errorCode, string? errorMessage, CancellationToken cancellationToken = default)
        => throw new NotImplementedException();
}

public class DummyDocumentExtractionProvider : IDocumentExtractionProvider
{
    public Task<DocumentIntelligence.Domain.DocumentExtractionResult> ExtractAsync(DocumentIntelligence.Domain.DocumentExtractionRequest request, CancellationToken cancellationToken = default)
        => throw new NotImplementedException();
}


---

2. Talking through the design (how you explain this in a meeting)

Here’s how you can walk people through what you just saw, in plain language:

1. We have a single microservice for all document types

It exposes a generic endpoint: POST /api/extraction.

The request has a DocumentType enum: Invoice, Payment, Deposit.

That means we don’t need a new service per type later.



2. The contract is stable and vendor-agnostic

The legacy system (or upload flow) only knows about:

DocumentId

BlobPath

DocumentType


It does not care if we use Azure today and AWS tomorrow.

That choice is behind IDocumentExtractionProvider.



3. We separate orchestration, providers, and persistence

ExtractionController → only handles HTTP & routing.

IExtractionOrchestrator → business flow:

Accept request

Possibly queue it

Call provider

Persist result


IDocumentExtractionProvider → “How do we actually talk to Azure/AWS/custom?”

IExtractionRepository → “How do we store/read extraction results from DB?”


This clean separation gives you:

Replaceable AI engine

Replaceable storage strategy

Testable logic



4. Future support for Payment / Deposit is already baked in

DocumentType enum already has Payment and Deposit.

Same request & status DTOs work for all types.

For payments and deposits, you’ll just:

Extend your normalized JSON schema (e.g., paymentType, reference, etc.)

Possibly implement type-specific logic inside the provider/orchestrator.




5. This aligns with your manager’s “blackbox” requirement

Legacy app just calls:

POST /api/extraction when a document is uploaded.

And later the Invoice.ASPX simply looks at DB (DocumentExtraction table) to prefill.


The microservice internal code can evolve (new AI, new model) without changing:

Legacy code

API contract

User flow






---

If you’d like, next we can:

Add type-safe invoice/payment/deposit JSON models that the microservice uses internally, while still storing raw JSON in the DB.

Draft the SQL schema for DocumentExtraction and show how Invoice.ASPX would query it.

Or sketch how to plug in Azure Document Intelligence behind IDocumentExtractionProvider (just signatures, no vendor lock-in).


≈===========

Nice, let’s turn this into a clean, “grown-up” solution that you can show to anyone and it will look well thought out.

I’ll give you:

1. Solution layout (projects)


2. Folder structure inside each project


3. How they reference each other


4. A short script you can use to explain this structure in the meeting.




---

1. Solution layout (projects)

Call the solution:

DocumentIntelligence.sln

Projects:

1. DocumentIntelligence.Api
ASP.NET Core Web API – controllers, DI, hosting.


2. DocumentIntelligence.Contracts
DTOs, enums, external contracts shared with legacy/other systems if needed.


3. DocumentIntelligence.Domain
Core domain models and logic, independent of infrastructure.


4. DocumentIntelligence.Application
Orchestration, use cases, business services (e.g., IExtractionOrchestrator).


5. DocumentIntelligence.Infrastructure
Implementations of repositories, providers (Azure/AWS/custom), DB, blob access, queue, etc.


6. DocumentIntelligence.Tests
Unit/integration tests.




---

2. Project structure (tree view)

2.1. DocumentIntelligence.Api (Web API)

DocumentIntelligence.Api
│
├── Controllers
│   └── ExtractionController.cs
│
├── Filters                (optional)
│   └── ExceptionHandlingFilter.cs
│
├── Configuration
│   └── ServiceRegistrationExtensions.cs
│   └── SwaggerExtensions.cs
│
├── appsettings.json
├── appsettings.Development.json
└── Program.cs

Responsibilities:

Expose endpoints like:

POST /api/extraction

GET /api/extraction/{documentId}


No business logic here – just HTTP → Application layer.


References:

References DocumentIntelligence.Application

References DocumentIntelligence.Contracts



---

2.2. DocumentIntelligence.Contracts

DocumentIntelligence.Contracts
│
├── Enums
│   ├── DocumentType.cs       // Invoice, Payment, Deposit, etc.
│   └── ExtractionStatus.cs
│
├── Requests
│   └── ExtractionRequestDto.cs
│
├── Responses
│   ├── ExtractionAcceptedResponseDto.cs
│   └── ExtractionStatusDto.cs
│
└── README.md                 // optional: describes contracts for consumers

Responsibilities:

Defines the public contract of the microservice.

Safe to share as a NuGet/package if another .NET app wants strong types.

Stable: changes here are versioned carefully.


References:

No references to other projects (contracts should be dependency-free).



---

2.3. DocumentIntelligence.Domain

DocumentIntelligence.Domain
│
├── Models
│   ├── DocumentExtractionRequest.cs
│   ├── DocumentExtractionResult.cs
│   │
│   ├── Invoice
│   │   ├── InvoiceHeader.cs
│   │   ├── InvoiceLineItem.cs
│   │   └── InvoiceExtractionModel.cs
│   │
│   ├── Payment
│   │   └── PaymentExtractionModel.cs   // for future
│   │
│   └── Deposit
│       └── DepositExtractionModel.cs   // for future
│
├── ValueObjects
│   ├── Money.cs
│   └── TaxAmount.cs
│
└── Services              (optional if you put core domain services here)
    └── INormalizationService.cs

Responsibilities:

Domain models and behavior, independent of tech:

DocumentExtractionRequest

DocumentExtractionResult

InvoiceExtractionModel etc.


Optional domain services (e.g., normalization logic).


References:

References DocumentIntelligence.Contracts (if you reuse enums like DocumentType).

No references to Infrastructure or API.



---

2.4. DocumentIntelligence.Application

DocumentIntelligence.Application
│
├── Interfaces
│   └── IExtractionOrchestrator.cs
│
├── Services
│   └── ExtractionOrchestrator.cs
│
├── Abstractions
│   ├── IExtractionRepository.cs
│   ├── IDocumentExtractionProvider.cs
│   ├── IBlobStorageClient.cs          // optional
│   └── IQueueClient.cs                // optional if you go async via queue
│
└── Mapping
    └── ExtractionMappingExtensions.cs // DTO <-> Domain mappers

Responsibilities:

Application/use-case orchestration, e.g.:

// Pseudocode inside ExtractionOrchestrator
// - validate the request
// - maybe enqueue or trigger async work
// - update status in DB
// - return "Accepted" result to caller

Uses abstractions:

IExtractionRepository to save/load from DB.

IDocumentExtractionProvider to call AI vendors.

IBlobStorageClient if needed to fetch docs.



References:

References DocumentIntelligence.Contracts

References DocumentIntelligence.Domain


> Important: Application knows only about interfaces for providers/repositories, not concrete implementations.




---

2.5. DocumentIntelligence.Infrastructure

DocumentIntelligence.Infrastructure
│
├── Persistence
│   ├── EntityFramework
│   │   ├── DocumentIntelligenceDbContext.cs
│   │   ├── Configurations
│   │   │   └── DocumentExtractionConfiguration.cs
│   │   └── Migrations (if needed)
│   │
│   ├── Models
│   │   └── DocumentExtractionEntity.cs  // maps to DB table
│   │
│   └── ExtractionRepository.cs          // implements IExtractionRepository
│
├── Providers
│   ├── Azure
│   │   └── AzureDocumentExtractionProvider.cs
│   ├── Aws
│   │   └── AwsDocumentExtractionProvider.cs   // future
│   └── Custom
│       └── CustomDocumentExtractionProvider.cs // future
│
├── Storage
│   └── BlobStorageClient.cs                // implements IBlobStorageClient
│
├── Messaging
│   └── QueueClient.cs                      // implements IQueueClient (Service Bus/SQS/etc.)
│
└── Configuration
    └── InfrastructureServiceRegistrationExtensions.cs

Responsibilities:

All tech-specific details:

How we talk to SQL/EF Core.

How we talk to Azure/AWS/custom AI.

How we talk to Blob storage.

How we talk to queues.


Implements Application abstractions:

ExtractionRepository : IExtractionRepository

AzureDocumentExtractionProvider : IDocumentExtractionProvider

BlobStorageClient : IBlobStorageClient

QueueClient : IQueueClient



References:

References DocumentIntelligence.Application

References DocumentIntelligence.Domain

References DocumentIntelligence.Contracts (if needed for enums, etc.)



---

2.6. DocumentIntelligence.Tests

DocumentIntelligence.Tests
│
├── Application
│   └── ExtractionOrchestratorTests.cs
│
├── Providers
│   └── AzureDocumentExtractionProviderTests.cs
│
└── Persistence
    └── ExtractionRepositoryTests.cs

Responsibilities:

Unit tests for orchestrator logic, provider mapping, repository behavior (with in-memory DB or test containers, depending on how far you want to go).


References:

References DocumentIntelligence.Application

References DocumentIntelligence.Domain

References DocumentIntelligence.Infrastructure

References DocumentIntelligence.Contracts



---

3. Project references (who depends on whom)

Think of it like layers:

[ API ]
  |
  v
[ Application ]
  |
  v
[ Domain ]
  ^
  |
[ Infrastructure ]  (plugged into Application via DI)

More concretely:

DocumentIntelligence.Api

→ DocumentIntelligence.Application

→ DocumentIntelligence.Contracts


DocumentIntelligence.Application

→ DocumentIntelligence.Domain

→ DocumentIntelligence.Contracts


DocumentIntelligence.Infrastructure

→ DocumentIntelligence.Application (to implement interfaces)

→ DocumentIntelligence.Domain

→ DocumentIntelligence.Contracts (if needed)


DocumentIntelligence.Domain

→ DocumentIntelligence.Contracts (optional, for enums)


DocumentIntelligence.Contracts

→ (no references)




---

4. How this connects back to your legacy Invoice.ASPX world

Here’s the story you can tell:

1. Upload flow (legacy app) calls:
POST /api/extraction on DocumentIntelligence.Api
→ which calls Application → which uses Infrastructure to:

Pull the document from blob

Call Azure/AWS/custom

Save JSON + metadata into DocumentExtraction table via EF repository.



2. Invoice.ASPX (legacy) does not call the microservice:

It simply queries your SQL DB for the DocumentExtraction row by DocumentId.

If JSON exists for an Invoice document → prefill fields.

If not → behave as it does today.



3. In Phase 2 or 3:

If you build a brand-new Angular/React invoice screen,

It can reuse the same DocumentIntelligence microservice and DB table.

Zero rework on the AI side.





---

5. How to explain this structure in the meeting (short script)

You can say something like:

> “We’ll build a small, focused DocumentIntelligence solution with clear separation of concerns.

Api is just the Web API controllers.

Contracts are the DTOs and enums that define our public interface.

Domain holds our core document and invoice models, independent of infrastructure.

Application orchestrates extraction, defines interfaces like IExtractionOrchestrator, IExtractionRepository, and IDocumentExtractionProvider.

Infrastructure plugs into these interfaces with actual implementations for SQL, Azure/AWS, blob storage, and queues.


This way, if we change our AI provider from Azure to AWS or to an internal engine, we only change the implementations in Infrastructure, not the API, not the application logic, and not the legacy Invoice.ASPX page.”




---

If you want, next we can:

Sketch the DocumentExtraction DB table (SQL DDL) that fits into this structure.

Or add a few concrete class stubs per project to help you scaffold this quickly in Visual Studio / Rider.
