#!/usr/bin/perl -w
use strict;

# Программа еще не закончена, в ней пока нет обработки пустых строк при поиске,
# (например, можно удалить все объекты при delete name="";
# и не используются модули и наследование, в которых я еще не разобрался.
# Например, search_book и delete_book полностью повторяют друг друга
# за исключением пары последних строк.

# Программа обрабатывает все опознанные ключи паттерна, а именно:
# name, author, shelf, reader, tag.
# Другие ключи игнорируются, но не объявляются ошибкой.

# Если выбирать файл для базы данных, отличный от books.txt,
# то его максимальная степень свободы задания данных - это
# больше или меньше пустых строк, а также возможность изменить
# последовательность: например сначала Author, а потом Title.
# Но первая буква должна быть заглавной, а разделителем быть двоеточие с пробелом. 

sub new {
    my $class = shift;
    my $self = {};
    bless ($self, $class);
    return $self;
}

my @books;

sub read_file {

    my $file; 
    unless ($file = shift) {print "\n\n  No database selected.\n\n\n"; return;}

    my $fh;
    unless (open ($fh, "<", $file)) {print "\n\n$file: No such file.\n\n\n"; return;}
    print "\n\n  Using $file:\n\n\n";
    @books = qw//;
    my $book;

    my $i = 1;
    while (<$fh>) {

        if ($_ eq "\n") {next;}
        chomp $_;
        if ($i % 5 == 1) {
            $book = main->new;
            push @books, $book;
        }  
        my ($key, $value) = (split /: /, $_, 2);
        $book->{$key} = $value;
        $i++;

    }
    return $file;
}


sub print_books {

     
    if (@_+0 == 0) {
        print "  Is empty.\n";
        print "\n\n";
        return;
    }


    foreach (@_) {
        print "    Title: ", $_->{Title}, "\n";
        print "    Author: " , $_->{Author}, "\n";
        print "    Section: ", $_->{Section}, "\n";
        print "    Shelf: ", $_->{Shelf}, "\n";
        print "    On Hands: ", $_->{"On Hands"}, "\n";
        print "\n\n";
    }
}

sub search_book {
    
    #Обработка кавычек для паттернов с пробелами.
    #Если в аргументе паттерна обнаруживается открытая кавычка,
    #то следующей аргумент считается частью первого, и все последующие,
    #до тех пор пока кавычка не будет закрыта. 
    for (my $i=0; $i<@_+0; $i++) {
        if ($_[$i] =~ /\"/) {
            while ($_[$i] !~ /\".*\"/) {
                if (defined $_[$i+1]) {
                    $_[$i] .= " $_[$i+1]";
                    splice (@_, $i+1, 1);
                } else {last;}
            }
        }
    }
  
    # Разделяем key и value по первому знаку "=".
    my %to_search;
    my ($search_key, $search_pattern);
    foreach (@_) {
        my $input = $_;
        ($search_key, $search_pattern) = (split/=/,$input,2);
        $to_search{$search_key} = $search_pattern;
    }

    # Все посторонние ключи отбрасываются.
    foreach my $key (keys %to_search) {
        my $del = 1;
        foreach ("name", "author", "reader", "shelf", "tag") {
            if ($key eq $_) {$del = 0; last;}
        }
        delete($to_search{$key}) if $del == 1;
    }

    # Из $value убираются кавычки для корректной обработки регулярного выражения.
    foreach my $value (values %to_search) {
         if (length($value)>2) {
            if (((substr($value, 0, 1) eq "\"") and (substr($value,-1) eq "\"")) 
            or ((substr($value,0,1) eq "\'") and (substr($value,-1) eq "\'")))
            {
                substr ($value, 0, 1) = "";
                substr ($value, -1) = "";
            }
        }
    } 

    
    # Для удобства ключи переименовываются идентично характеристикам объекта.
    $to_search{Section} = delete $to_search{name} if defined $to_search{name};
    $to_search{Author} = delete $to_search{author} if defined $to_search{author};
    $to_search{"On Hands"} = delete $to_search{reader} if defined $to_search{reader};
    $to_search{Shelf} = delete $to_search{shelf} if defined $to_search{shelf};
    $to_search{Title} = delete $to_search{tag} if defined $to_search{tag};

    # Если ни один из ключей не завалил регулярку, то паттерн для объекта выполняется.
    foreach my $book (@books) {
        my $not_match = 0;
        foreach my $key (keys %to_search) { 
            unless ($book->{$key} =~ /$to_search{$key}/i) {
                $not_match = 1;
                last;
            }
        }
        print_books($book) if $not_match == 0;
    }
}

sub delete_book {

    print "\n\n";

    for (my $i=0; $i<@_+0; $i++) {
        if ($_[$i] =~ /\"/) {
            while ($_[$i] !~ /\".*\"/) {
                if (defined $_[$i+1]) {
                    $_[$i] .= " $_[$i+1]";
                    splice (@_, $i+1, 1);
                } else {last;}
            }
        }
    }

    my %to_search;
    my ($search_key, $search_pattern);
    foreach (@_) {
        my $input = $_;
        ($search_key, $search_pattern) = (split/=/,$input,2);
        $to_search{$search_key} = $search_pattern;
    }
    
    foreach my $key (keys %to_search) {
        my $del = 1;
        foreach ("name", "author", "reader", "shelf", "tag") {
            if ($key eq $_) {$del = 0; last;}
        }
        delete($to_search{$key}) if $del == 1;
    }

    foreach my $value (values %to_search) {
         if (length($value)>2) {
            if (((substr($value, 0, 1) eq "\"") and (substr($value,-1) eq "\""))
            or ((substr($value,0,1) eq "\'") and (substr($value,-1) eq "\'")))
            {
                substr ($value, 0, 1) = "";
                substr ($value, -1) = "";
            }
        }
    }
    $to_search{Section} = delete $to_search{name} if defined $to_search{name};
    $to_search{Author} = delete $to_search{author} if defined $to_search{author};
    $to_search{"On Hands"} = delete $to_search{reader} if defined $to_search{reader};
    $to_search{Shelf} = delete $to_search{shelf} if defined $to_search{shelf};
    $to_search{Title} = delete $to_search{tag} if defined $to_search{tag};

    my $deleted = 0;
    my $i = 0;
    while ($i < @books+0) {
        my $not_match = 0;
        foreach my $key (keys %to_search) {
            unless ($books[$i]->{$key} =~ /$to_search{$key}/i) {
                $not_match = 1;
                last;
            }
        }
        if ($not_match == 0) {
            splice (@books,$i,1);
            $deleted++;
        } 
        else {$i++};
    }
    print "  $deleted book(s) has been deleted\n\n\n";
}

sub add_book {

    my $book = main->new;
    print "\n\n  Set the fields for a new book:\n\n\n";
    foreach ("Title", "Author", "Section", "Shelf", "On Hands") {
        print "    $_: ";
        $book->{$_} = <STDIN>;
        chomp $book->{$_};
    }
    push @books, $book;
    
    print "\n\n  The new book has been added\n\n\n";
}



sub input_dispatcher {
    
    my $input = shift;

    if ($input eq "load") {
        my $file = shift;
        my $db = read_file($file);
        return $db if defined $db;
        return "";
    }

    elsif ($input eq "p") {
        print "\n\n";
        print_books(@books);
        return "";
    }

    elsif ($input eq "search") {
        print "\n\n";
        search_book(@_);
        return "";
    }

    elsif ($input eq "add") {
        add_book;
        return "";
    }

    elsif ($input eq "delete") {
        delete_book(@_);
        return "";
    }

    elsif ($input eq "q") {
        exit;
    }
    
    else {
        print "\n\n";
        print "  Command invalid.\n";
        print "\n\n";
        return "";
    }
}


# Пока что информация об использовании паттерна выводится каждый раз перед ожиданием ввода.
print "[load [file] - load database, search [pattern] - search by a given pattern]\n";
print "[delete [pattern] - delete by a give pattern, add - add new book]\n";
print "[Use the following syntax for pattern:\n";
print "> search|delete name=VAL1 author=VAL2 shelf=VAL3 reader=VAL4 tag=VAL5]\n";
print "[p - print all, q - quit]\n";
