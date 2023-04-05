# Define the compiler and flags
JAVAC = javac
JFLAGS = -g -cp src 

# Define the directories
SRCDIR = src
BINDIR = bin

# Define the sources and objects
SOURCES := $(wildcard $(SRCDIR)/*.java)
OBJECTS := $(patsubst $(SRCDIR)/%.java,$(BINDIR)/%.class,$(SOURCES))

# Define the targets
all: $(OBJECTS)

$(BINDIR)/%.class: $(SRCDIR)/%.java
	$(JAVAC) $(JFLAGS) -d $(BINDIR) $<

clean:
	rm -f $(BINDIR)/*.class
