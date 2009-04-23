#--
#Copyright 2007 Nominet UK
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License. 
#You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0 
#
#Unless required by applicable law or agreed to in writing, software 
#distributed under the License is distributed on an "AS IS" BASIS, 
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
#See the License for the specific language governing permissions and 
#limitations under the License.
#++
module Dnsruby
  class Recursor
    class AddressCache
      # Like an array, but stores the expiration of each record.
      def initialize(*args)
        @hash = Hash.new # stores addresses against their expiration
      end
      def push(item)
        address, ttl = item
        expiration = Time.now + ttl
        @hash[address] = expiration
      end
      def values
        ret =[]
        keys_to_delete = []
        @hash.keys.each {|address|
          if (@hash[address] > Time.now)
            ret.push(address)
          else
            keys_to_delete.push(address)
          end
        }
        keys_to_delete.each {|key|
          @hash.delete(key)
        }
        return ret
      end
      def length
        return @hash.length
      end
      def each()
        values.each {|v|
          yield v
        }
      end
    end
    #= NAME
    #
    #Dnsruby::Recursor - Perform recursive dns lookups
    #
    #= SYNOPSIS
    #
    #  require 'Dnsruby'
    #  rec = Dnsruby::Recursor.new()
    #  answer = rec.recurse("rob.com.au")
    #
    #= DESCRIPTION
    #
    #This module uses a Dnsruby::Resolver or Dnsruby::SingleResolver to
    #perform recursive queries.
    #
    #=head1 AUTHOR
    #
    #Rob Brown, bbb@cpan.org
    #Alex Dalitz, alexd@nominet.org.uk
    #
    #=head1 SEE ALSO
    #
    #L<Dnsruby::Resolver>,
    #
    #=head1 COPYRIGHT
    #
    #Copyright (c) 2002, Rob Brown.  All rights reserved.
    #Portions Copyright (c) 2005, Olaf M Kolkman.
    #Ruby version Copyright (c) 2008, AlexD (Nominet UK)
    #
    #Example lookup process:
    #
    #[root@box root]# dig +trace www.rob.com.au.
    #
    #; <<>> DiG 9.2.0 <<>> +trace www.rob.com.au.
    #;; global options:  printcmd
    #.                       507343  IN      NS      C.ROOT-SERVERS.NET.
    #.                       507343  IN      NS      D.ROOT-SERVERS.NET.
    #.                       507343  IN      NS      E.ROOT-SERVERS.NET.
    #.                       507343  IN      NS      F.ROOT-SERVERS.NET.
    #.                       507343  IN      NS      G.ROOT-SERVERS.NET.
    #.                       507343  IN      NS      H.ROOT-SERVERS.NET.
    #.                       507343  IN      NS      I.ROOT-SERVERS.NET.
    #.                       507343  IN      NS      J.ROOT-SERVERS.NET.
    #.                       507343  IN      NS      K.ROOT-SERVERS.NET.
    #.                       507343  IN      NS      L.ROOT-SERVERS.NET.
    #.                       507343  IN      NS      M.ROOT-SERVERS.NET.
    #.                       507343  IN      NS      A.ROOT-SERVERS.NET.
    #.                       507343  IN      NS      B.ROOT-SERVERS.NET.
    #;; Received 436 bytes from 127.0.0.1#53(127.0.0.1) in 9 ms
    #  ;;; But these should be hard coded as the hints
    #
    #  ;;; Ask H.ROOT-SERVERS.NET gave:
    #au.                     172800  IN      NS      NS2.BERKELEY.EDU.
    #au.                     172800  IN      NS      NS1.BERKELEY.EDU.
    #au.                     172800  IN      NS      NS.UU.NET.
    #au.                     172800  IN      NS      BOX2.AUNIC.NET.
    #au.                     172800  IN      NS      SEC1.APNIC.NET.
    #au.                     172800  IN      NS      SEC3.APNIC.NET.
    #;; Received 300 bytes from 128.63.2.53#53(H.ROOT-SERVERS.NET) in 322 ms
    #  ;;; A little closer than before
    #
    #  ;;; Ask NS2.BERKELEY.EDU gave:
    #com.au.                 259200  IN      NS      ns4.ausregistry.net.
    #com.au.                 259200  IN      NS      dns1.telstra.net.
    #com.au.                 259200  IN      NS      au2ld.CSIRO.au.
    #com.au.                 259200  IN      NS      audns01.syd.optus.net.
    #com.au.                 259200  IN      NS      ns.ripe.net.
    #com.au.                 259200  IN      NS      ns1.ausregistry.net.
    #com.au.                 259200  IN      NS      ns2.ausregistry.net.
    #com.au.                 259200  IN      NS      ns3.ausregistry.net.
    #com.au.                 259200  IN      NS      ns3.melbourneit.com.
    #;; Received 387 bytes from 128.32.206.12#53(NS2.BERKELEY.EDU) in 10312 ms
    #  ;;; A little closer than before
    #
    #  ;;; Ask ns4.ausregistry.net gave:
    #com.au.                 259200  IN      NS      ns1.ausregistry.net.
    #com.au.                 259200  IN      NS      ns2.ausregistry.net.
    #com.au.                 259200  IN      NS      ns3.ausregistry.net.
    #com.au.                 259200  IN      NS      ns4.ausregistry.net.
    #com.au.                 259200  IN      NS      ns3.melbourneit.com.
    #com.au.                 259200  IN      NS      dns1.telstra.net.
    #com.au.                 259200  IN      NS      au2ld.CSIRO.au.
    #com.au.                 259200  IN      NS      ns.ripe.net.
    #com.au.                 259200  IN      NS      audns01.syd.optus.net.
    #;; Received 259 bytes from 137.39.1.3#53(ns4.ausregistry.net) in 606 ms
    #  ;;; Uh... yeah... I already knew this
    #  ;;; from what NS2.BERKELEY.EDU told me.
    #  ;;; ns4.ausregistry.net must have brain damage
    #
    #  ;;; Ask ns1.ausregistry.net gave:
    #rob.com.au.             86400   IN      NS      sy-dns02.tmns.net.au.
    #rob.com.au.             86400   IN      NS      sy-dns01.tmns.net.au.
    #;; Received 87 bytes from 203.18.56.41#53(ns1.ausregistry.net) in 372 ms
    #  ;;; Ah, much better.  Something more useful.
    #
    #  ;;; Ask sy-dns02.tmns.net.au gave:
    #www.rob.com.au.         7200    IN      A       139.134.5.123
    #rob.com.au.             7200    IN      NS      sy-dns01.tmns.net.au.
    #rob.com.au.             7200    IN      NS      sy-dns02.tmns.net.au.
    #;; Received 135 bytes from 139.134.2.18#53(sy-dns02.tmns.net.au) in 525 ms
    #  ;;; FINALLY, THE ANSWER!
    attr_accessor :nameservers, :callback, :recurse, :ipv6_ok
    attr_reader :hints
    # The resolver to use for the queries
    attr_accessor :resolver
        
    def initialize(res = Resolver.new)
      @resolver = res
      @ipv6_ok = false
    end
    #Initialize the hint servers.  Recursive queries need a starting name
    #server to work off of. This method takes a list of IP addresses to use
    #as the starting servers.  These name servers should be authoritative for
    #the root (.) zone.
    #
    #  res.hints=(ips)
    #
    #If no hints are passed, the default nameserver is asked for the hints. 
    #Normally these IPs can be obtained from the following location:
    #
    #  ftp://ftp.internic.net/domain/named.root
    #  
    def hints=(hints)
      TheLog.debug(";; hints(#{hints.inspect})\n")
      if (!hints && @nameservers)
        @hints=(@nameservers)
      else
        @nameservers=(hints)
      end
      TheLog.debug(";; verifying (root) zone...\n")
      # bind always asks one of the hint servers
      # for who it thinks is authoritative for
      # the (root) zone as a sanity check.
      # Nice idea.
          
      @resolver.recurse=(1)
      packet=@resolver.query(".", "NS", "IN")
      hints = Hash.new
      if (packet)
        if (ans = packet.answer)
          ans.each do |rr|
            if (rr.name.to_s =~ /^\.?$/ and
                  rr.type == Types.NS)
              # Found root authority
              server = rr.nsdname.to_s.downcase
              server.sub!(/\.$/,"")
              TheLog.debug(";; FOUND HINT: #{server}\n")
              hints[server] = AddressCache.new
            end
          end
          packet.additional.each do |rr|
            TheLog.debug(";; ADDITIONAL: "+rr.inspect+"\n")
            server = rr.name.to_s.downcase
            server.sub!(/\.$/,"")
            if (server)
              if ( rr.type == Types.A)
                #print ";; ADDITIONAL HELP: $server -> [".$rr->rdatastr."]\n" if $self->{'debug'};
                if (hints[server]!=nil)
                  TheLog.debug(";; STORING IP: #{server} IN A "+rr.address.to_s+"\n")
                  hints[server].push([rr.address.to_s, rr.ttl])
                end
              end
              if ( rr.type == Types.AAAA)
                #print ";; ADDITIONAL HELP: $server -> [".$rr->rdatastr."]\n" if $self->{'debug'};
                if (hints[server])
                  TheLog.debug(";; STORING IP6: #{server} IN AAAA "+rr.address.to_s+"\n")
                  hints[server].push([rr.address.to_s, rr.ttl])
                end
              end
                  
            end 
          end
        end
        #                      foreach my $server (keys %hints) {
        hints.keys.each do |server|
          if (!hints[server] || hints[server].length == 0)
            # Wipe the servers without lookups
            hints.delete(server)
          end
        end
        @hints = hints
      else
        @hints = {}
      end
      if (@hints.size > 0)
        if (@debug)
          TheLog.info(";; USING THE FOLLOWING HINT IPS:\n")
          @hints.values.each do |ips|
            ips.each do |server|
              TheLog.info(";;  #{server}\n")
            end
          end
        end
      else
        warn "Server ["+(@nameservers)[0].to_s+"] did not give answers"
      end
          
      # Disable recursion flag.
      @resolver.recurse=(0)
          
      #  return $self->nameservers( map { @{ $_ } } values %{ $self->{'hints'} } );
      @nameservers = @hints.values
      return @nameservers
    end
        
        
    #This method takes a code reference, which is then invoked each time a
    #packet is received during the recursive lookup.  For example to emulate
    #dig's C<+trace> function:
    #
    # res.recursion_callback(Proc.new { |packet|
    #     print packet.additional.inspect
    #		
    #     print";; Received %d bytes from %s\n\n", 
    #         packetanswersize, 
    #         packet.answerfrom);
    # })
    #
    def recursion_callback=(sub)
      #          if (sub && UNIVERSAL::isa(sub, 'CODE'))
      @callback = sub
      #          end
    end  
        
    def recursion_callback
      return @callback
    end
        
    #This method is much like the normal query() method except it disables
    #the recurse flag in the packet and explicitly performs the recursion.
    #
    #  packet = res.query_dorecursion( "www.netscape.com.", "A")
    #
    #
    def query(name, type=Types.A, klass=Classes.IN)
          
      # Make sure the hint servers are initialized.
      self.hints=(Hash.new) unless @hints
      @resolver.recurse=(0)
      # Make sure the authority cache is clean.
      # It is only used to store A and AAAA records of
      # the suposedly authoritative name servers.
      # TTLs are respected
      if (!@authority_cache)
        @authority_cache = Hash.new
      end
      if (!@zones_cache)
        @zones_cache = Hash.new # key zone_name, values Hash of servers and AddressCaches
        @zones_cache["."] = @hints
      end

      # So we have normal hashes, but the array of addresses at the end is now an AddressCache
      # which respects the ttls of the A/AAAA records

      # Now see if we already know the zone in question
      # Otherwise, see if we know any of its parents (will know at least ".")
      known_zone, known_authorities = get_closest_known_zone_authorities_for(name) # ".", @hints if nothing else

      # Seed name servers with the closest known authority
      #      ret =  _dorecursion( name, type, klass, ".", @hints, 0)
      ret =  _dorecursion( name, type, klass, known_zone, known_authorities, 0)
      Dnssec.validate(ret)
      #      print "\n\nRESPONSE:\n#{ret}\n"
      return ret
    end

    def get_closest_known_zone_for(n)
      # Find the closest parent of name that we know
      # e.g. for nominet.org.uk, try nominet.org.uk., org.uk., uk., .
      # does @zones_cache contain the name we're after
      name = n.tr("","")
      if (name[name.length-1] != ".")
        name = name + "."
      end

      while (true)
#        print "Checking for known zone : #{name}\n"
        zone = @zones_cache[name]
        if (zone != nil)
          return name
        end
        return false if name=="." 
        # strip the name up to the first dot
        first_dot = name.index(".")
        if (first_dot == (name.length-1))
          name = "."
        else
          name = name[first_dot+1, name.length]
        end
      end
    end

    def get_closest_known_zone_authorities_for(name)
      done = false
      known_authorities, known_zone = nil
      while (!done)
        known_zone = get_closest_known_zone_for(name)
#        print "GOT KNOWN ZONE : #{known_zone}\n"
        known_authorities = @zones_cache[known_zone] # ".", @hints if nothing else
#        print "Known authorities : #{known_authorities}\n"

        # Make sure that known_authorities still contains some authorities!
        # If not, remove the zone from zones_cache, and start again
        if (known_authorities.values.length > 0)
          done = true
        else
          @zones_cache.delete(known_zone)
        end
      end
      return known_zone, known_authorities
    end
        
    def _dorecursion(name, type, klass, known_zone, known_authorities, depth)
      cache = @authority_cache # this acts as a store of known server_names - NOT zones
          
      if ( depth > 255 )
        TheLog.debug(";; _dorecursion() Recursion too deep, aborting...\n")
        @errorstring="Recursion too deep, aborted"
        return nil
      end
          
      known_zone.sub!(/\.*$/, ".")
          
      # Get IPs from authorities
      ns = [] # Array of AddressCaches (was array of array of addresses)
      known_authorities.keys.each do |ns_rec|
        if (known_authorities[ns_rec] != nil  && known_authorities[ns_rec] != [] )
          cache[ns_rec] = known_authorities[ns_rec]
          ns.push(cache[ns_rec])
        elsif (cache[ns_rec]!=nil && cache[ns_rec]!=[])
          known_authorities[ns_rec] = cache[ns_rec]
          ns.push(cache[ns_rec])
        end
      end
          
      if (ns.length == 0)
        found_auth = 0
        TheLog.debug(";; _dorecursion() Failed to extract nameserver IPs:\n")
        TheLog.debug(known_authorities.inspect + cache.inspect + "\n")
        known_authorities.keys.each do |ns_rec|
          if (known_authorities[ns_rec]==nil || known_authorities[ns_rec]==[])
            TheLog.debug(";; _dorecursion() Manual lookup for authority [#{ns_rec}]\n")
                
            auth_packet=nil
            ans=[]
                
            # Don't query for V6 if its not there.
            if ( @ipv6_ok)
              auth_packet = _dorecursion(ns_rec,"AAAA", klass,  # packet
                ".",               # known_zone
                @hints,  # known_authorities
                depth+1);         # depth
              ans = auth_packet.answer if auth_packet
            end
                
            auth_packet = _dorecursion(ns_rec,"A",klass,  # packet
              ".",               # known_zone
              @hints,  # known_authorities
              depth+1);         # depth
                
            ans.push(auth_packet.answer ) if auth_packet
                
            if ( ans.length > 0 )
              TheLog.debug(";; _dorecursion() Answers found for [#{ns_rec}]\n")
              #          foreach my $rr (@ans) {
              ans.each do |rr_arr|
                rr_arr.each do |rr|
                  TheLog.debug(";; RR:" + rr.inspect + "\n")
                  if (rr.type == Types.CNAME)
                    # Follow CNAME
                    server = rr.name.to_s.downcase
                    if (server)
                      server.sub!(/\.*$/, ".")
                      if (server == ns_rec)
                        cname = rr.cname.downcase
                        cname.sub!(/\.*$/, ".")
                        TheLog.debug(";; _dorecursion() Following CNAME ns [#{ns_rec}] -> [#{cname}]\n")
                        if (!(known_authorities[cname]))
                          known_authorities[cname] = AddressCache.new
                        end
                        known_authorities.delete(ns_rec)
                        next
                      end
                    end
                  elsif (rr.type == Types.A || rr.type == Types.AAAA )
                    server = rr.name.to_s.downcase
                    if (server)
                      server.sub!(/\.*$/, ".")
                      if (known_authorities[server]!=nil)
                        ip = rr.address.to_s
                        TheLog.debug(";; _dorecursion() Found ns: #{server} IN A #{ip}\n")
                        cache[server] = known_authorities[server]
                        cache[ns_rec].push([ip, rr.ttl])
                        found_auth+=1
                        next
                      end
                    end
                  end
                  TheLog.debug(";; _dorecursion() Ignoring useless answer: " + rr.inspect + "\n")
                end
              end
            else
              TheLog.debug(";; _dorecursion() Could not find A records for [#{ns_rec}]\n")
            end
          end
        end
        if (found_auth > 0)
          TheLog.debug(";; _dorecursion() Found #{found_auth} new NS authorities...\n")
          return _dorecursion( name, type, klass, known_zone, known_authorities, depth+1)
        end
        TheLog.debug(";; _dorecursion() No authority information could be obtained.\n")
        return nil
      end
          
      # Cut the deck of IPs in a random place.
      TheLog.debug(";; _dorecursion() cutting deck of (" + ns.length.to_s + ") authorities...\n")
      splitpos = rand(ns.length)
      start = ns[0, splitpos]
      endarr = ns[splitpos, ns.length - splitpos]
      ns = endarr + start
          
          
      ns.each do |nss|
        nss.each do |levelns|
          TheLog.debug(";; _dorecursion() Trying nameserver [#{levelns}]\n")
          #        @nameservers=(levelns)
          #
          #        packet = @resolver.query( name, type, klass )
          resolver = SingleResolver.new(levelns.to_s)
          begin
            # Should construct packet ourselves and clear RD bit
            query = Message.new(name, type, klass)
            query.header.rd = false
            query.do_validation = false # @TODO@ !!!
            #            print "Sending msg from resolver, dnssec = #{resolver.dnssec}, do_validation = #{query.do_validation}\n"
            packet = resolver.send_message(query)
          rescue ResolvTimeout, IOError => e
            TheLog.debug(";; nameserver #{levelns.to_s} didn't respond\n")
            next
          end
          if (packet) # @TODO@ Check that the packet *is* actually authoritative!!
            if (@callback)
              @callback.call(packet)
            end
              
            of = nil
            TheLog.debug(";; _dorecursion() Response received from [" + @answerfrom.to_s + "]\n")
            status = packet.rcode
            authority = packet.authority
            if (status)
              if (status == "NXDOMAIN")
                # I guess NXDOMAIN is the best we'll ever get
                TheLog.debug(";; _dorecursion() returning NXDOMAIN\n")
                return packet
              elsif (packet.answer.length > 0)
                TheLog.debug(";; _dorecursion() Answers were found.\n")
                return packet
              elsif (authority.length > 0)
                auth = Hash.new
                #	 foreach my $rr (@authority) {
                authority.each do |rr|
                  if (rr.type.to_s =~ /^(NS|SOA)$/)
                    server = (rr.type == Types.NS ? rr.nsdname : rr.mname).to_s.downcase
                    server.sub!(/\.*$/, ".")
                    of = rr.name.to_s.downcase
                    of.sub!(/\.*$/, ".")
                    TheLog.debug(";; _dorecursion() Received authority [#{of}] [" + rr.type().to_s + "] [#{server}]\n")
                    if (of.length <= known_zone.length)
                      TheLog.debug(";; _dorecursion() Deadbeat name server did not provide new information.\n")
                      next
                    elsif (of =~ /#{known_zone}/)
                      TheLog.debug(";; _dorecursion() FOUND closer authority for [#{of}] at [#{server}].\n")
                      auth[server] ||= AddressCache.new #[]
                    else
                      TheLog.debug(";; _dorecursion() Confused name server [" + @answerfrom + "] thinks [#{of}] is closer than [#{known_zone}]?\n")
                      last
                    end
                  else
                    TheLog.debug(";; _dorecursion() Ignoring NON NS entry found in authority section: " + rr.inspect + "\n")
                  end
                end
                #	 foreach my $rr ($packet->additional)
                packet.additional.each do |rr|
                  if (rr.type == Types.CNAME)
                    # Store this CNAME into %auth too
                    server = rr.name.to_s.downcase
                    if (server)
                      server.sub!(/\.*$/, ".")
                      if (auth[server]!=nil && auth[server].length > 0)
                        cname = rr.cname.to_s.downcase
                        cname.sub!(/\.*$/, ".")
                        TheLog.debug(";; _dorecursion() FOUND CNAME authority: " + rr.string + "\n")
                        auth[cname] ||= AddressCache.new # []
                        auth[server] = auth[cname]
                        next
                      end
                        
                    end
                  elsif (rr.type == Types.A || rr.type == Types.AAAA)
                    server = rr.name.to_s.downcase
                    if (server)
                      server.sub!(/\.*$/, ".")
                      if (auth[server]!=nil)
                        if (rr.type == Types.A)
                          TheLog.debug(";; _dorecursion() STORING: #{server} IN A    " + rr.address.to_s + "\n")
                        end
                        if (rr.type == Types.AAAA)
                          TheLog.debug(";; _dorecursion() STORING: #{server} IN AAAA " + rr.address.to_s + "\n")
                        end
                        auth[server].push([rr.address.to_s, rr.ttl])
                        next
                      end
                    end
                  end
                  TheLog.debug(";; _dorecursion() Ignoring useless: " + rr.inspect + "\n")
                end
                if (of =~ /#{known_zone}/)
#                  print "Adding #{of} with :\n#{auth}\nto zones_cache\n"
                  @zones_cache[of]=auth
                  return _dorecursion( name, type, klass, of, auth, depth+1 )
                else
                  return _dorecursion( name, type, klass, known_zone, known_authorities, depth+1 )
                end
              end
            end
          end
        end
      end
          
      return nil
    end
  end
end